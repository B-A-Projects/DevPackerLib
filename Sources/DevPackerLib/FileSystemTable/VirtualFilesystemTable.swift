//
//  VirtualFilesystemTableHeader.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 21/01/2025.
//

import Foundation

struct VirtualFilesystemTable: FilesystemTable {
    
    var id: UInt32
    
    var partitionOffset: UInt64
    
    var fileOffsetFactor: UInt32
    
    var groupHeaderCount: UInt32
    
    var groupHeaders: [FileSystemTableGroupHeader]
    
    var entryTable: FileSystemTableEntry
    
    init() throws {
        entryTable = try FileSystemTableEntry(Name: "", EntryType: .Folder, Index: 0, SubEntries: [
            try FileSystemTableEntry(Name: "2", EntryType: .Folder, Index: 1, SubEntries: [
                try FileSystemTableEntry(Name: "title.cert", EntryType: .File, Index: 2),
                try FileSystemTableEntry(Name: "title.tik", EntryType: .File, Index: 3),
                try FileSystemTableEntry(Name: "title.tmd", EntryType: .File, Index: 4)
            ]),
        ])
        
        fileOffsetFactor = 0x20
        partitionOffset = 0
        groupHeaderCount = 0
    }
    
    func extract(EntryIndex index: UInt32, ExtractionPath directory: URL, File reader: (any Reader)?, DecryptionKey key: [UInt8]?) throws {
        <#code#>
    }
    
    func extract(FileSystemEntry entry: FileSystemTableEntry, ExtractionPath directory: URL, File reader: (any Reader)?, DecryptionKey key: [UInt8]?) throws {
        <#code#>
    }
    
    func parse(EntryIndex index: UInt32, File reader: (any Reader)?, DecryptionKey key: [UInt8]?) throws -> [UInt8] {
        <#code#>
    }
    
    func parse(FileSystemEntry entry: FileSystemTableEntry, File reader: (any Reader)?, DecryptionKey key: [UInt8]?) throws -> [UInt8] {
        <#code#>
    }
}
