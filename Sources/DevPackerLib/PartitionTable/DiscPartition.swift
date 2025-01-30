//
//  Partition.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 24/01/2025.
//

import Foundation
import CryptoSwift

struct DiscPartition: Partition {
    
    public var partitionName: String { get { return _partitionName } }
    
    public var partitionType: PartitionType { get { return _partitionType } }
    
    public var filesystemTable: FilesystemTable { get { return _filesystemTable } }
    
    private var _partitionName: String
    private var _partitionType: PartitionType
    private var _filesystemTable: FilesystemTable
    private var _key: [UInt8]? = nil
    
    private var _partitionOffset: UInt64 = 0
    private var _filesystemTableOffset: UInt64 = 0
    private var _partitionSize: UInt64 = 0
    private var _filesystemTableSize: UInt64 = 0
    private var _hashBlockSize: UInt32 = 0
    private var _hashCount: UInt32 = 0
    
    private var _ticket: Ticket? = nil
    private var _metadata: Metadata? = nil
    private var _certificateChain: Signature? = nil
    
    private var _getDirectoryUrl: () -> URL
    
//    var partitionName: String
//    
//    var type: PartitionType
//    
//    var offset: UInt64
//    
//    var filesystemTableOffset: UInt64
//    
//    var partitionSize: UInt64
//    
//    var hashBlockSize: UInt32
//    
//    var hashCount: UInt32
//    
//    var filesystemTableSize: UInt32
    
    public init(PartitionType type: PartitionType,
                DirectoryUrl url: URL,
                DecryptionKey key: [UInt8]? = nil,
                Ticket ticket: Ticket? = nil,
                Metadata metadata: Metadata? = nil,
                CertificateChain certificateChain: Signature? = nil
    ) throws {
        _partitionType = type
        _ticket = ticket
        _metadata = metadata
        _certificateChain = certificateChain
        
        switch type {
        case .System:
            _partitionName = type.Value
            _filesystemTable = try VirtualFilesystemTable()
        case .Game:
            guard key != nil && _ticket != nil && _metadata != nil else {
                throw ReadError.Uninitialized
            }
            _partitionName = "GM\(_ticket!.primaryHeader.titleId.toHexString())000000000000"
            _key = try _ticket!.getDecryptionKey(DecryptionKey: key!)
            
            let filesystemUrl = url.append(Component: "\(metadata!.contentChunks[0].chunkFileName).app")
            guard filesystemUrl.fileExists() else {
                throw ReadError.FileNotFound
            }
            let fileReader = try BinaryReader(Order: .BigEndian, Path: filesystemUrl)
            let encryptedFilesystemTable = try fileReader.readUnsignedByteArray(ByteCountToRead: fileReader.length)
            
            let aes = try AES(key: _key!,
                              blockMode: CBC(iv: Array(repeating: 0, count: 0x10)),
                              padding: .noPadding)
            var memoryReader = try MemoryReader(From: aes.decrypt(encryptedFilesystemTable),
                                                ByteOrder: .BigEndian)
            _filesystemTable = try DiscFilesystemTable(PartitionName: _partitionName,
                                                       File: memoryReader,
                                                       DirectoryPath: url)
        default:
            throw ReadError.InvalidValue
        }
    }
    
    public init(File reader: Reader,
                DecryptionKey key: [UInt8]? = nil,
                Ticket ticket: Ticket? = nil,
                Metadata metadata: Metadata? = nil,
                CertificateChain certificateChain: Signature? = nil
    ) throws {
        _key = key
        _ticket = ticket
        _metadata = metadata
        _certificateChain = certificateChain
        
        // Read out the partition table entry
        let baseOffset = reader.offset
        _partitionName = try reader.readString()
        _partitionType = PartitionType.Parse(Value: partitionName)
        
        try reader.seek(Offset: baseOffset + 0x20)
        let offsetValue = try reader.readInteger<UInt32>() as UInt64
        _partitionOffset = offsetValue << 0xF
        
        // Read out the partition header
        guard try reader.readInteger(Offset: _partitionOffset) == 0xCC93A4F5 else {
            throw ReadError.InvalidValue
        }
        
        let headerSize = try reader.readInteger<UInt32>() as UInt64
        _filesystemTableOffset = _partitionOffset + headerSize
        
        let size: UInt32 = try reader.readInteger()
        _partitionSize = UInt64(size) << 15
        
        _hashBlockSize = try reader.readInteger()
        _hashCount = try reader.readInteger()
        _filesystemTableSize = try reader.readInteger<UInt32>() as UInt64
        
        // Parse the filesystem table
        let encryptedFilesystemTable = try reader.readUnsignedByteArray(ByteCountToRead: _filesystemTableSize,
                                                                         Offset: _filesystemTableOffset)
        
        if _key != nil {
            guard _ticket != nil else {
                throw ReadError.Uninitialized
            }
            
            let aes = try AES(key: _key!,
                              blockMode: CBC(iv: Array(repeating: 0, count: 0x10)),
                              padding: .noPadding)
            var memoryReader = try MemoryReader(From: aes.decrypt(encryptedFilesystemTable),
                                                ByteOrder: .BigEndian)
            _filesystemTable = try DiscFilesystemTable(PartitionName: _partitionName,
                                                       File: memoryReader,
                                                       DirectoryPath: url)

        }
        
        try reader.seek(Offset: baseOffset + 0x80)
    }
    
    public func Extract(SourceUrl source: URL,
                        DestinationUrl destination: URL,
                        FilesystemTableIndex filesystemTableIndex: UInt32,
                        DecryptionKey key: [UInt8]? = nil
    ) throws {
        let tableEntry = _filesystemTable.entryTable.getEntry(Index: filesystemTableIndex)
        guard tableEntry != nil else {
            throw ReadError.FileNotFound
        }
        
        let wudUrl = source.append(Component: "game.wud")
        guard wudUrl.fileExists() else {
            throw ReadError.FileNotFound
        }
        
        var partitionReader: Reader = try BinaryReader(Order: .BigEndian,
                                             Path: wudUrl)
        if key != nil {
            let aes = try AES(key: _key!,
                              blockMode: CBC(iv: Array(repeating: 0, count: 0x10)),
                              padding: .noPadding)
            partitionReader = try MemoryReader(From: aes.decrypt(partitionReader.readUnsignedByteArray(ByteCountToRead: _partitionSize,
                                                                                                       Offset: _partitionOffset)),
                                               ByteOrder: .BigEndian)
        } else {
            partitionReader = try MemoryReader(From: partitionReader.readUnsignedByteArray(ByteCountToRead: _partitionOffset,
                                                                                           Offset: _partitionSize),
                                               ByteOrder: .BigEndian)
        }
        
    }
    
    private func getChunk(Group groupEntry: FileSystemTableGroupHeader,
                          FileOffset fileOffset: UInt64,
                          FileSize fileSize: UInt64
    ) throws -> [UInt8] {
        var directoryUrl = _getDirectoryUrl()
        
        let wudUrl = directoryUrl.append(Component: "game.wud")
        guard wudUrl.fileExists() else {
            throw ReadError.FileNotFound
        }
        
        let encryptionOffset: UInt64 = (_key != nil && fileOffset > 0 ? 0x10 : 0)
        let absoluteOffset = _partitionOffset + groupEntry.groupOffset + fileOffset - encryptionOffset
        var partitionReader = try BinaryReader(Order: .BigEndian,
                                               Path: wudUrl)
        var chunkBytes = try partitionReader.readUnsignedByteArray(ByteCountToRead: fileSize,
                                                                   Offset: absoluteOffset)
        
        if _key != nil {
            let aes = try AES(key: _key!,
                              blockMode: CBC(iv: Array(repeating: 0, count: 0x10)),
                              padding: .noPadding)
            return try aes.decrypt(Array(chunkBytes[Int(encryptionOffset)...]))
        }
        return chunkBytes
    }
}
