//
//  File.swift
//  
//
//  Created by Yannick de Boer on 12/07/2024.
//

import Foundation
import CryptoSwift

public struct DiscFilesystemTable: FilesystemTable {
    
    public var id: String
    
    /// Represents the number by which file offsets need to be multiplied.
    var fileOffsetFactor: UInt32
    
    /// Contains the filesystem table groups  for this
    var groupHeaders: [FileSystemTableGroupHeader] { get { return _groupHeaders } }
    
    /// Contains the filesystem in a file tree structure, the topmost record representing the root of the file tree.
    public var entryTable: FileSystemTableEntry { get { return _entryTable } }
    
    /// Determines if the partition in which this
    /// filesystem table is located is a system
    /// partition. Encrypted system partitions use
    /// different initialization vectors for
    /// decryption.
    var isSystem: Bool
    
    private var _key: [UInt8]? = nil
    private var _fileOffsetFactor: UInt32 = 0
    
    private var _groupHeaders: [FileSystemTableGroupHeader]
    private var _entryTable: FileSystemTableEntry
    
    private var _getChunk: (_ groupEntry: FileSystemTableGroupHeader,
                            _ fileOffset: UInt64,
                            _ fileSize: UInt64
    ) throws -> [UInt8]
    
    public init(File reader: Reader,
                FilesystemTableOffset offset: UInt64,
                FilesystemTableSize size: UInt64,
                PartitionName name: String,
                DecryptionKey key: [UInt8]?
    ) throws {
        _key = key
        
        var filesystemReader = reader
        if _key != nil {
            let aes = try AES(key: _key!,
                              blockMode: CBC(iv: Array(repeating: 0, count: 0x10)),
                              padding: .noPadding)
            filesystemReader = try MemoryReader(From: aes.decrypt(reader.readUnsignedByteArray(ByteCountToRead: size)),
                                                ByteOrder: .BigEndian)
        }
        
        let identifier = try filesystemReader.readInteger(Offset: offset) as UInt32
        guard identifier == 0x46535400 else {
            throw ReadError.InvalidValue
        }
        
        _fileOffsetFactor = try filesystemReader.readInteger()
        let groupHeaderCount: UInt32 = try filesystemReader.readInteger()
        guard groupHeaderCount > 0 else {
            //TODO: Add proper error
            throw ReadError.InvalidValue
        }
        
        try reader.seek(Offset: filesystemReader.offset + 0x14)
        _groupHeaders = []
        for header in 0...groupHeaderCount - 1 {
            _groupHeaders.insert(try FileSystemTableGroupHeader(File: filesystemReader,
                                                                Index: UInt16(header)),
                                at: Int(header))
        }
        
        let entryListOffset = offset +  0x20 + UInt64(groupHeaderCount * 0x20)
        let entryCount = try reader.readInteger(Offset: entryListOffset + 0x8,
                                                IsPeek: true) as UInt32
        let nameTableOffset = offset + 0x20 + UInt64(groupHeaderCount * 0x20) + UInt64(entryCount * 0x10)
        
        _entryTable = try FileSystemTableEntry(File: reader,
                                               EntryListOffset: entryListOffset,
                                               NameTableOffset: nameTableOffset)
    }
    
    /// Extracts a file or folder defined in the filesystem table from a CDN chunk or disc image.
    ///
    /// Any other value will result in
    /// `FileSystemTableEntryType.Unknown`
    ///
    /// - Parameters:
    ///     - EntryIndex: The zero-based index of the entry in the **`entryTable`** . This index is used to retrieve the entry to extract.
    ///     - PartitionOffset: The offset to the start of the partition in which the data is located. This value is always 0 when extracting from CDN content.
    ///     - ExtractionPath: the directory in which to extract the filesystem table entry.
    ///     - File: The disc image stream from which the filesystem table entry is being extracted. This steam is not used for CDN content.
    ///     - DecryptionKey: The key used to decrypt content stored in the **`ContentChunks`**.  This key is not used for unencrypted (development/kiosk) content.
    public func Extract(FilesystemTableIndex filesystemTableIndex: UInt32,
                        DestinationUrl destination: URL
    ) throws {
        let tableEntry = entryTable.getEntry(Index: filesystemTableIndex)
        guard tableEntry != nil else {
            throw ReadError.FileNotFound
        }
        try tableEntry!.extract(DestinationUrl: destination,
                                getFile: getFile(ChunkIndex:FileOffset:FileSize:))
        
    }
    
    internal func getFile(ChunkIndex index: UInt32,
                          FileOffset offset: UInt64,
                          FileSize size: UInt64
    ) throws -> [UInt8] {
        guard index < _groupHeaders.count else {
            throw ReadError.InvalidValue
        }
        let groupEntry = groupHeaders[Int(index)]
                                
        var fileGroupOffset: UInt64 = 0
        var fileGroupSize: UInt64 = 0
        var hashTreeIndex: UInt64 = 0
        
        if groupEntry.hasHashTree {
            fileGroupOffset = offset * 0x8000
            var fileSectorCount: UInt64 = (size + (size % 0x7C00)) / 0x7C00
            fileGroupSize = fileSectorCount * 0x8000
            hashTreeIndex = offset % 0x10
        } else {
            fileGroupOffset = offset * UInt64(fileOffsetFactor)
            fileGroupSize = size + (size % UInt64(fileOffsetFactor))
        }
            
        let encryptionOffset: UInt64 = (_key != nil && fileGroupOffset > 0 ? 0x10 : 0)
        let chunk = try _getChunk(groupEntry,
                                  offset - encryptionOffset,
                                  fileGroupSize + encryptionOffset)
            
        if _key != nil {
            let reader = try MemoryReader(From: Array(chunk[Int(encryptionOffset)...]),
                                          ByteOrder: .BigEndian)
            return try decrypt(File: reader,
                               FileOffset: fileGroupOffset,
                               FileLength: fileGroupSize,
                               GroupEntry: groupEntry,
                               HashTreeIndex: hashTreeIndex)
        }
        return chunk
    }
    
    private func decrypt(File reader: Reader,
                         FileOffset offset: UInt64,
                         FileLength length: UInt64,
                         GroupEntry groupEntry: FileSystemTableGroupHeader,
                         HashTreeIndex index: UInt64 = 0
    ) throws -> [UInt8] {
        if groupEntry.hasHashTree {
            return try decryptHashTreeChunk(File: reader,
                                            GroupEntry: groupEntry,
                                            HashTreeIndex: index,
                                            FileOffset: offset,
                                            FileLength: length)
        }
        return try decryptRegularChunk(File: reader,
                                       GroupEntryIndex: groupEntry.index,
                                       FileOffset: offset,
                                       FileLength: length)
    }
    
    private func decryptHashTreeChunk(File reader: Reader,
                                      GroupEntry groupEntry: FileSystemTableGroupHeader,
                                      HashTreeIndex index: UInt64,
                                      FileOffset offset: UInt64,
                                      FileLength length: UInt64
    ) throws -> [UInt8] {
        return []
    }
    
    private func decryptRegularChunk(File reader: Reader,
                                     GroupEntryIndex groupIndex: UInt16,
                                     FileOffset offset: UInt64,
                                     FileLength length: UInt64
    ) throws -> [UInt8] {
        try reader.seek(Offset: offset * UInt64(fileOffsetFactor))
        let data = try reader.readUnsignedByteArray(ByteCountToRead: length)
        
        var iv = Array.init(repeating: UInt8(0), count: 16)
        if isSystem {
            let sectorIndex = UInt16((offset - 0x10000) / 0x10000)
            for index in 0...1 {
                iv[15 - index] = UInt8((sectorIndex >> (index * 8)) & 0xFF)
            }
        } else {
            for index in 0...1 {
                iv[1 - index] = UInt8((groupIndex >> (index * 8)) & 0xFF)
            }
        }
        
        let decryptor = try AES(key: _key!, blockMode: CBC(iv: iv), padding: .noPadding)
        let decryptedData = try decryptor.decrypt(data)
        
        let memoryReader = try MemoryReader(From: data, ByteOrder: .BigEndian)
        try memoryReader.seek(Offset: offset)
        return try memoryReader.readUnsignedByteArray(ByteCountToRead: length, Offset: 0, IsPeek: false)
    }
    
    public init(File reader: Reader,
                PartitionName name: String,
                DirectoryPath path: URL?
    ) throws {
        id = name
        self.isSystem = name == "SI"
        let baseOffset = reader.offset
        
        let identifier = try reader.readInteger() as UInt32
        guard identifier == 0x46535400 else {
            throw ReadError.InvalidValue
        }
        
        fileOffsetFactor = try reader.readInteger()
        groupHeaderCount = try reader.readInteger()
        guard groupHeaderCount > 0 else {
            //TODO: Add proper error
            throw ReadError.InvalidValue
        }
        
        try reader.seek(Offset: reader.offset + 0x14)
        groupHeaders = []
        for header in 0...groupHeaderCount - 1 {
            groupHeaders.insert(try FileSystemTableGroupHeader(File: reader,
                                                               Index: header + 1,
                                                               IsSystemPartition: isSystem,
                                                               DirectoryPath: path),
                                at: Int(header))
        }
        
        let entryListOffset = baseOffset +  0x20 + UInt64(groupHeaderCount * 0x20)
        let entryCount = try reader.readInteger(Offset: entryListOffset + 0x8,
                                                IsPeek: true) as UInt32
        let nameTableOffset = baseOffset + 0x20 + UInt64(groupHeaderCount * 0x20) + UInt64(entryCount * 0x10)
        
        entryTable = try FileSystemTableEntry(File: reader,
                                              EntryListOffset: entryListOffset,
                                              NameTableOffset: nameTableOffset)
    }
}
