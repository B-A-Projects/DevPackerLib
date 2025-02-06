//
//  Partition.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 24/01/2025.
//

import Foundation
import CryptoSwift

public struct DiscPartition: Partition {
    
    public var partitionName: String { get { return _partitionName } }
    
    public var partitionType: PartitionType { get { return _partitionType } }
    
    public var filesystemTable: FilesystemTable { get { return _filesystemTable! } }
    
    private var _partitionName: String
    private var _partitionType: PartitionType
    private var _partitionIndex: UInt32
    private var _partitionOffset: UInt64 = 0
    private var _partitionSize: UInt64 = 0
    
    private var _filesystemTableOffset: UInt64 = 0
    private var _filesystemTableSize: UInt64 = 0
    private var _filesystemTable: FilesystemTable? = nil
    
    private var _hashBlockSize: UInt32 = 0
    private var _hashCount: UInt32 = 0
    
    private var _ticket: Ticket? = nil
    private var _metadata: Metadata? = nil
    private var _certificateChain: Signature? = nil
    
    private var _key: [UInt8]? = nil
    
    internal var _getDirectoryUrl: () -> URL
    internal var _getSystemFiles: (_ index: UInt32) throws -> (Signature, Ticket, Metadata)?
    
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: PartitionKeys.self)
        _partitionName = try values.decodeIfPresent(String.self, forKey: .partitionName) ?? "default"
        _partitionIndex = try values.decodeIfPresent(UInt32.self, forKey: .partitionIndex) ?? 0
        _partitionType = try values.decodeIfPresent(PartitionType.self, forKey: .partitionType) ?? .Game
        _partitionOffset = try values.decodeIfPresent(UInt64.self, forKey: .partitionSize) ?? 0
        _partitionSize = try values.decodeIfPresent(UInt64.self, forKey: .partitionSize) ?? 0
        
        _filesystemTableOffset = try values.decodeIfPresent(UInt64.self, forKey: .filesystemTableOffset) ?? 0
        _filesystemTableSize = try values.decodeIfPresent(UInt64.self, forKey: .filesystemTableSize) ?? 0
        _filesystemTable = try values.decodeIfPresent(FilesystemTable.self, forKey: .filesystemTable)!
        
        _hashBlockSize = try values.decodeIfPresent(UInt32.self, forKey: .hashBlockSize) ?? 0
        _hashCount = try values.decodeIfPresent(UInt32.self, forKey: .hashCount) ?? 0
        
        _ticket = try values.decodeIfPresent(Ticket.self, forKey: .ticket)
        _metadata = try values.decodeIfPresent(Metadata.self, forKey: .metadata)
        _certificateChain = try values.decodeIfPresent(Signature.self, forKey: .signature)
        
        _key = try values.decodeIfPresent([UInt8].self, forKey: .key)
        
        _getDirectoryUrl = { URL(fileURLWithPath: "/") }
        _getSystemFiles =  { partitionIndex in return nil }
        
        _filesystemTable!._getGroup = getGroup(Group:FileOffset:FileSize:)
    }
    
    public init(File reader: Reader,
                PartitionIndex index: UInt32,
                GetSystemFiles: @escaping (_ partitionIndex: UInt32) throws -> (Signature, Ticket, Metadata)?,
                GetDirectoryUrl: @escaping () -> URL,
                DecryptionKey key: [UInt8]? = nil
    ) throws {
        // Read out the partition table entry
        let baseOffset = reader.offset
        _partitionName = try reader.readString()
        _partitionType = PartitionType.Parse(Value: _partitionName)
        _partitionIndex = index
        _getSystemFiles = GetSystemFiles
        _getDirectoryUrl = GetDirectoryUrl
        
        switch _partitionType {
        case .Game:
            let systemFiles = try GetSystemFiles(_partitionIndex)
            _certificateChain = systemFiles?.0
            _ticket = systemFiles?.1
            _metadata = systemFiles?.2
        default:
            _key = key
        }
        _key = key
        
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
        let filesystemTable = try reader.readUnsignedByteArray(ByteCountToRead: _filesystemTableSize,
                                                               Offset: _filesystemTableOffset)
        
        if _key != nil {
            let aes = try AES(key: _key!,
                              blockMode: CBC(iv: Array(repeating: 0, count: 0x10)),
                              padding: .noPadding)
            var memoryReader = try MemoryReader(From: aes.decrypt(filesystemTable),
                                                ByteOrder: .BigEndian)
            _filesystemTable = try FilesystemTable(File: memoryReader,
                                                   FilesystemTableOffset: 0,
                                                   FilesystemTableSize: _filesystemTableSize,
                                                   PartitionName: _partitionName,
                                                   GetGroup: getGroup(Group:FileOffset:FileSize:),
                                                   DecryptionKey: nil)
        } else {
            var memoryReader = try MemoryReader(From: filesystemTable,
                                                ByteOrder: .BigEndian)
            _filesystemTable = try FilesystemTable(File: memoryReader,
                                                   FilesystemTableOffset: 0,
                                                   FilesystemTableSize: _filesystemTableSize,
                                                   PartitionName: _partitionName,
                                                   GetGroup: getGroup(Group:FileOffset:FileSize:),
                                                   DecryptionKey: _ticket?.primaryHeader.decryptedTitleKey ?? nil)
        }
        
        try reader.seek(Offset: baseOffset + 0x80)
    }
    
    public func extract(DestinationUrl destination: URL?,
                                 FilesystemTableIndex filesystemTableIndex: UInt32
    ) throws -> [UInt8]? {
        return try _filesystemTable!.Extract(FilesystemTableIndex: filesystemTableIndex,
                                             DestinationUrl: destination)
    }
    
    /// Reads a specified range of bytes at the
    /// offset in the `FileSystemTableGroupHeader`
    /// entry provided.
    ///
    /// This function reads a specified range of
    /// bytes at an offset relative to the starting
    /// position of the `FileSystemTableGroupHeader`
    /// in this partition.
    ///
    /// If the `_key` property is set, decryption is
    /// performed on the partition level.
    ///
    /// - Parameters:
    ///     - Group: The `FileSystemTableGroupHeader` entry in which the file to be extracted is located.
    ///     - FileOffset: 0-based offset at which the file is located within the partition.
    ///     - FileSize: The total size of the file to be extracted, in bytes. For files in groups using hash trees, this number should be the total size of sectors in bytes.
    ///
    /// - Returns: An `UInt8` array containing the specified
    /// range of bytes from the specified
    /// `FileSystemTableGroupHeader` entry.
    private func getGroup(Group groupEntry: FileSystemTableGroupHeader,
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
            var iv = Array.init(repeating: UInt8(0), count: 16)
            if _partitionType == .System {
                let sectorIndex = UInt16((fileOffset - 0x10000) / 0x10000)
                for index in 0...1 {
                    iv[15 - index] = UInt8((sectorIndex >> (index * 8)) & 0xFF)
                }
            } else {
                for index in 0...1 {
                    iv[1 - index] = UInt8((groupEntry.index >> (index * 8)) & 0xFF)
                }
            }
            
            let aes = try AES(key: _key!,
                              blockMode: CBC(iv: Array(repeating: 0, count: 0x10)),
                              padding: .noPadding)
            return try aes.decrypt(Array(chunkBytes[Int(encryptionOffset)...]))
        }
        return chunkBytes
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: PartitionKeys.self)
        try container.encode(_partitionName, forKey: .partitionName)
        try container.encode(_partitionIndex, forKey: .partitionIndex)
        try container.encode(_partitionType, forKey: .partitionType)
        try container.encode(_partitionOffset, forKey: .partitionOffset)
        try container.encode(_partitionSize, forKey: .partitionSize)
        
        try container.encode(_filesystemTableOffset, forKey: .filesystemTableOffset)
        try container.encode(_filesystemTableSize, forKey: .filesystemTableSize)
        try container.encode(_filesystemTable, forKey: .filesystemTable)
        
        try container.encode(_hashBlockSize, forKey: .hashBlockSize)
        try container.encode(_hashCount, forKey: .hashCount)
        
        try container.encodeIfPresent(_ticket, forKey: .ticket)
        try container.encodeIfPresent(_metadata, forKey: .metadata)
        try container.encodeIfPresent(_certificateChain, forKey: .signature)
        
        try container.encodeIfPresent(_key, forKey: .key)
    }
}
