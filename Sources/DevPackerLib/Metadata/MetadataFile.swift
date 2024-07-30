//
//  MetadataFile.swift
//
//
//  Created by Yannick de Boer on 18/07/2024.
//

import Foundation

/// Represents the metadata file.
public struct MetadataFile: Codable {
    
    /// Represents the signature of the metadata header structure.
    var signature: Signature
    
    /// Represents the main header structure of the metadata file.
    var header: MetadataHeader
    
    /// Represents the list of content groups present in the metadata file.
    var contentGroups: [MetadataContentGroupEntry]
    
    /// Represents the list of content chunks that are related to this metadata file.
    var contentChunks: [MetadataContentChunkEntry]
    
    init(File fileHandle: Reader) throws {
        signature = try Signature(File: fileHandle)
        header = try MetadataHeader(File: fileHandle)
        
        contentGroups = []
        for index in 0...63 {
            contentGroups.insert(try MetadataContentGroupEntry(File: fileHandle), at: index)
        }
        
        contentChunks = []
        let chunkCount = Int(contentGroups.map({ $0.chunkCount }).reduce(0, +));
        for index in 0...chunkCount {
            contentChunks.insert(try MetadataContentChunkEntry(File: fileHandle), at: index)
        }
    }
}
