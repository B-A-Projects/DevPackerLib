//
//  File.swift
//  
//
//  Created by Yannick de Boer on 12/07/2024.
//

import Foundation

public struct FilesystemTableHeader: Codable, Identifiable {
    
    public var id: String
    
    /// Represents the number by which file offsets need to be multiplied.
    var fileOffsetFactor: UInt32
    
    /// Represents the amount of group headers stored in this file table.
    var groupHeaderCount: UInt32
    
    /// Contains the filesystem table groups  for this
    var groupHeaders: [FileSystemTableGroupHeader]
    
    /// Contains the filesystem in a file tree structure, the topmost record representing the root of the file tree.
    public var entryTable: FileSystemTableEntry
    
    /// Determines if the partition in which this
    /// filesystem table is located is a system
    /// partition. Encrypted system partitions use
    /// different initialization vectors for
    /// decryption.
    var isSystem: Bool
    
    public init(PartitionName name: String,
                File reader: Reader,
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
    public func extract(EntryIndex index: UInt32,
                        PartitionOffset offset: UInt64,
                        ExtractionPath directory: URL,
                        File reader: Reader?,
                        DecryptionKey key: [UInt8]?
    ) throws {
        if index == 0 {
            //TODO: Add proper error
            throw ReadError.InvalidValue
        }
        
        let entry = entryTable.getEntry(Index: index)
        guard entry != nil else {
            //TODO: Add proper error
            throw ReadError.InvalidValue
        }
        
        try extract(FileSystemEntry: entry!,
                    PartitionOffset: offset,
                    ExtractionPath: directory,
                    File: reader,
                    DecryptionKey: key)
    }
    
    public func extract(FileSystemEntry entry: FileSystemTableEntry,
                        PartitionOffset offset: UInt64,
                        ExtractionPath directory: URL,
                        File reader: Reader?,
                        DecryptionKey key: [UInt8]?
    ) throws {
        switch entry.type {
        case .File:
            try extractFile(FileSystemEntry: entry,
                            PartitionOffset: offset,
                            ExtractionPath: directory,
                            File: reader,
                            DecryptionKey: key)
        case .Folder:
            try extractFolder(FileSystemEntry: entry,
                              PartitionOffset: offset,
                              ExtractionPath: directory,
                              File: reader,
                              DecryptionKey: key)
        default:
            //TODO: Add proper error
            throw ReadError.Uninitialized
        }
    }
    
    private func extractFile(FileSystemEntry entry: FileSystemTableEntry,
                             PartitionOffset offset: UInt64,
                             ExtractionPath directory: URL,
                             File reader: Reader?,
                             DecryptionKey key: [UInt8]?
    ) throws {
        let groupIndex = Int(entry.groupHeaderIndex)
        try reader?.seek(Offset: offset)
        
        var fileBytes = try groupHeaders[groupIndex].Read(FileOffset: UInt64(entry.offset),
                                                          FileLength: UInt64(entry.byteSize),
                                                          File: reader!,
                                                          DecryptionKey: key)
        try entry.extract(BaseDirectory: directory,
                          FileData: fileBytes)
    }
    
    private func extractFolder(FileSystemEntry entry: FileSystemTableEntry,
                               PartitionOffset offset: UInt64,
                               ExtractionPath directory: URL,
                               File reader: Reader?,
                               DecryptionKey key: [UInt8]?
    ) throws {
        try entry.extract(BaseDirectory: directory, FileData: nil)
        
        let subDirectoryUrl = directory.append(Component: entry.name)
        guard entry.subEntries != nil else {
            //TODO: Add proper error
            throw ReadError.InvalidValue
        }
        
        for subEntry in entry.subEntries! {
            try extract(FileSystemEntry: subEntry,
                        PartitionOffset: offset,
                        ExtractionPath: directory,
                        File: reader,
                        DecryptionKey: key)
        }
    }
}
