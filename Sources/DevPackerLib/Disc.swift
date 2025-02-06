//
//  Disc.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 15/01/2025.
//

import Foundation
import CryptoSwift

public struct Disc: Game {
    
    public var name: String { get { return _name } }
    
    public var consoleType: ConsoleType { get { return _consoleType } }
    
    public var mediaType: MediaType { get { return _mediaType } }
    
    public var partitions: [Partition] { get { return _partitions } }
    
    public var directoryUrl: URL { get { return _directoryUrl } }
    
    /// Contains the disc title key for disc-based Wii U titles, used for decrypting non-game master partitions.
    private var _titleKey: [UInt8]
    
    /// Contains the Wii U common key, used for decrypting the encrypted title keys in ticket files for game master partitions.
    private var _commonKey: [UInt8]
    
    private var _name: String
    private var _directoryUrl: URL
    private var _consoleType: ConsoleType
    private var _mediaType: MediaType
    private var _partitions: [DiscPartition]
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: GameKeys.self)
        _name = try container.decode(String.self, forKey: .name)
        _directoryUrl = try container.decode(URL.self, forKey: .directoryUrl)
        _consoleType = try container.decode(ConsoleType.self, forKey: .consoleType)
        _mediaType = try container.decode(MediaType.self, forKey: .mediaType)
        _partitions = try container.decode([DiscPartition].self, forKey: .partitions)
        _titleKey = try container.decode([UInt8].self, forKey: .titleKey)
        _commonKey = try container.decode([UInt8].self, forKey: .commonKey)
        
        for index in 0..._partitions.count - 1 {
            _partitions[index]._getSystemFiles = GetSystemFiles(PartitionIndex:)
            _partitions[index]._getDirectoryUrl = GetDirectoryUrl
        }
    }
    
    public init(Directory url: URL,
                TitleKey titleKey: [UInt8],
                CommonKey commonKey: [UInt8],
                ConsoleType type: ConsoleType
    ) throws {
        _mediaType = .Disc
        _consoleType = type
        _directoryUrl = url
        _titleKey = titleKey
        _commonKey = commonKey
        
        let wudUrl = url.append(Component: "game.wud")
        guard wudUrl.fileExists() else {
            throw ReadError.FileNotFound
        }
        
        var reader = try BinaryReader(Order: .BigEndian, Path: wudUrl)
        _name = try reader.readString()
        
        var tableReader: Reader
        if try reader.readInteger(Offset: 0x18000) as UInt32 == 0xCCA6E67B {
            var tableBytes = try reader.readUnsignedByteArray(ByteCountToRead: 0x8000, Offset: 0x18000)
            tableReader = try MemoryReader(From: tableBytes, ByteOrder: .BigEndian)
        } else {
            var tableBytes = try reader.readUnsignedByteArray(ByteCountToRead: 0x8000, Offset: 0x18000)
            var decryptor = try AES(key: titleKey,
                                    blockMode: CBC(iv: Array(repeating: 0, count: 0x10)),
                                    padding: .noPadding)
            tableReader = try MemoryReader(From: try decryptor.decrypt(tableBytes), ByteOrder: .BigEndian)
        }
        
        guard try tableReader.readInteger() == 0xCCA6E67B else {
            throw ReadError.InvalidValue
        }
        
        let headerSize: UInt32 = try tableReader.readInteger()
        
        try tableReader.seek(Offset: tableReader.offset + 0x14)
        let partitionCount = try tableReader.readInteger() as UInt32
        
        _partitions = []
        try tableReader.seek(Offset: tableReader.offset + 0x7E0)
        for index in 0...partitionCount {
            switch _consoleType {
            case .Retail:
                _partitions.insert(try DiscPartition(File: tableReader,
                                                     PartitionIndex: UInt32(index),
                                                     GetSystemFiles: GetSystemFiles(PartitionIndex:),
                                                     GetDirectoryUrl: GetDirectoryUrl,
                                                     DecryptionKey: titleKey),
                                   at: Int(index))
            case .Development:
                _partitions.insert(try DiscPartition(File: tableReader,
                                                     PartitionIndex: UInt32(index),
                                                     GetSystemFiles: GetSystemFiles(PartitionIndex:),
                                                     GetDirectoryUrl: GetDirectoryUrl,
                                                     DecryptionKey: nil),
                                   at: Int(index))
            default:
                throw ReadError.InvalidValue
            }
        }
    }
    
    public func extract(DestinationUrl url: URL,
                        PartitionIndex partitionIndex: UInt32,
                        FilesystemTableIndex filesystemTableIndex: UInt32
    ) throws {
        guard partitionIndex < _partitions.count else {
            throw ReadError.InvalidValue
        }
        try _partitions[Int(partitionIndex)].extract(DestinationUrl: url,
                                                     FilesystemTableIndex: filesystemTableIndex)
    }
    
    private func GetSystemFiles(PartitionIndex index: UInt32) throws -> (Signature, Ticket, Metadata)? {
        var entry = partitions[0].filesystemTable.entryTable.getEntry(Name: String(index))
        guard entry != nil || entry?.subEntries?.count != 3 else {
            return nil
        }
        
        let signatureBytes = try _partitions[0].extract(DestinationUrl: nil,
                                                        FilesystemTableIndex: entry!.subEntries![0].index)
        let ticketBytes = try _partitions[0].extract(DestinationUrl: nil,
                                                     FilesystemTableIndex: entry!.subEntries![1].index)
        let metadataBytes = try _partitions[0].extract(DestinationUrl: nil,
                                                       FilesystemTableIndex: entry!.subEntries![2].index)
        guard signatureBytes != nil && ticketBytes != nil && metadataBytes != nil else {
            return nil
        }
        
        return (
            try Signature(File: try MemoryReader(From: signatureBytes!,
                                                 ByteOrder: .BigEndian)),
            try Ticket(File: try MemoryReader(From: ticketBytes!,
                                              ByteOrder: .BigEndian),
                       DecryptionKey: _commonKey),
            try Metadata(File: try MemoryReader(From: metadataBytes!,
                                                ByteOrder: .BigEndian))
        )
    }
    
    private func GetDirectoryUrl() -> URL {
        return directoryUrl
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: GameKeys.self)
        try container.encode(_name, forKey: .name)
        try container.encode(_directoryUrl, forKey: .directoryUrl)
        try container.encode(_consoleType, forKey: .consoleType)
        try container.encode(_mediaType, forKey: .mediaType)
        try container.encode(_partitions, forKey: .partitions)
        try container.encode(_titleKey, forKey: .titleKey)
        try container.encode(_commonKey, forKey: .commonKey)
    }
}
