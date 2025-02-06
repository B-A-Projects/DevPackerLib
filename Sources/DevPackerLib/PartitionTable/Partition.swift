//
//  Partition.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 03/02/2025.
//

import Foundation

public protocol Partition: Codable {
    
    /// The name of the partition, as defined in the partition table.
    var partitionName: String { get }
    
    /// The type of the partition.
    var partitionType: PartitionType { get }
    
    /// The filesystem table for this partition.
    var filesystemTable: FilesystemTable { get }
    
    
    /// Extracts a speficied entity from the
    /// selected partition's filesystem table, and
    /// writes them to a specified location on the
    /// host machine.
    ///
    /// The amount of entities getting extracted
    /// depends on the `FileSystemTableEntryType`
    /// of the selected entry.
    /// Entities marked as `Folder` will also have
    /// the content they contain extracted.
    ///
    /// - Parameters:
    ///     - DestinationUrl: The value of which to determine the type.
    ///     - FilesystemTableIndex: The 0-based index at which the entity to be extracted can be found inside of the filesystem table.
    ///
    /// - Returns: If no destination URL is provided, an `UInt8` array containing the decrypted output of the selected file is returned. Otherwise, `nil` is returned.
    func extract(DestinationUrl destination: URL?,
                 FilesystemTableIndex filesystemTableIndex: UInt32
    ) throws -> [UInt8]?
}
