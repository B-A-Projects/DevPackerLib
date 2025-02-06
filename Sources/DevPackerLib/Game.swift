//
//  WiiUGame.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 23/01/2025.
//

import Foundation
import CryptoSwift

/// A type that represents a type of content
/// package targeting the Wii U.
///
/// The Game protocol defines a number of
/// standard properties that should be
/// publicly accessible and implemented in
/// deriving classes. The `Codable`
/// protocol is inherited to enforce the ability to
/// encode and decode the structure.
public protocol Game: Codable {
    
    /// Represents the name of the media.
    var name: String { get }
    
    /// Represents the the type of hardware the package is configured to run on.
    var consoleType: ConsoleType { get }
    
    /// Represents the type of media the package originates from.
    var mediaType: MediaType { get }
    
    /// Contains all partitions stored in this video game package.
    var partitions: [Partition] { get }
    
    /// The URL pointing to the directory in which the files related to this video game are located.
    var directoryUrl: URL { get }
    
    
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
    ///     - PartitionIndex: The 0-based index of the partition in which the entity to be extracted is located.
    ///     - FilesystemTableIndex: The 0-based index at which the entity to be extracted can be found inside of the filesystem table.
    func extract(DestinationUrl url: URL,
                 PartitionIndex partitionIndex: UInt32,
                 FilesystemTableIndex filesystemTableIndex: UInt32
    ) throws
    
}
