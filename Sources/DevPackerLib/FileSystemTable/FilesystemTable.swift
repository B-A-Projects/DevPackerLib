//
//  VirtualFilesystemTableHeader.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 21/01/2025.
//

import Foundation

protocol FilesystemTable: Codable {
    
    // var id: UInt32 { get }
    
    /// Represents the offset at which the
    /// partition starts. The start of the partition
    /// is defined as the first sector following the
    /// partition header and filesystem table.
    var partitionOffset: UInt64 { get }
    
    /// Represents the number by which file offsets need to be multiplied.
    var fileOffsetFactor: UInt32 { get }
    
    /// Represents the amount of `GroupHeader` objects stored in this file table.
    var groupHeaderCount: UInt32 { get }
    
    /// Contains the filesystem table groups
    /// defined in the filesystem table as
    /// `GroupHeader` objects
    var groupHeaders: [FileSystemTableGroupHeader] { get }
    
    /// Contains the filesystem in a file tree
    /// structure, the topmost record
    /// representing the root of the file tree.
    var entryTable: FileSystemTableEntry { get }
    
    
    func extract(EntryIndex index: UInt32, ExtractionPath directory: URL, File reader: (any Reader)?, DecryptionKey key: [UInt8]?) throws
    
    func extract(FileSystemEntry entry: FileSystemTableEntry, ExtractionPath directory: URL, File reader: (any Reader)?, DecryptionKey key: [UInt8]?) throws
    
    func parse(EntryIndex index: UInt32, File reader: (any Reader)?, DecryptionKey key: [UInt8]?) throws -> [UInt8]
    
    func parse(FileSystemEntry entry: FileSystemTableEntry, File reader: (any Reader)?, DecryptionKey key: [UInt8]?) throws -> [UInt8]
    
}
