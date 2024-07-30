//
//  MetadataContentGroupEntry.swift
//
//
//  Created by Yannick de Boer on 12/07/2024.
//

import Foundation

/// Represents an entry in the content group
/// table of the metadata file. 
///
/// A content group consists of a number of
/// **`MetadataContentChunkEntry`**
/// objects. Each group entry is sequential,
/// with the index of the first chunk entry 
/// being the sum of all previous group entry
/// **`chunkCount`** values.
public struct MetadataContentGroupEntry: Codable {
    
    /// The amount of **`MetadataContent`
    /// `ChunkEntry`** objects that are related to
    /// this group entry.
    var chunkCount: UInt32
    
    /// The SHA1 hash computed using the
    /// **`MetadataContentChunkEntry`**
    /// objects in sequential orderlinked to this
    /// entry as input.
    var chunkHash: [UInt8]
    
    init (File fileHandle: Reader) throws {
        chunkCount = try fileHandle.readUnsignedInt(Offset: nil, IsPeek: false)
        chunkHash = try fileHandle.readUnsignedByteArray(ByteCountToRead: 0x20, Offset: nil, IsPeek: false)
    }
}
