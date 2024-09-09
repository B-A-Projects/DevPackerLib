//
//  MetadataFile.swift
//
//
//  Created by Yannick de Boer on 18/07/2024.
//

import Foundation

/// Represents the metadata file, including all 
/// substructures of the file.
public struct Metadata: Codable {
    
    /// Represents the signature of the metadata header structure.
    var signature: Signature
    
    /// Represents the main header structure of the metadata file.
    var header: MetadataHeader
    
    /// Represents the list of content groups present in the metadata file.
    var contentGroups: [MetadataContentGroupEntry]
    
    /// Represents the list of content chunks that are related to this metadata file.
    var contentChunks: [MetadataContentChunkEntry]
    
    init(DirectoryUrl url: URL) throws {
        let metadataUrl = url.append(Component: "title.tmd")
        
        let reader = try BinaryReader(Order: .BigEndian, Path: metadataUrl)
        signature = try Signature(File: reader)
        header = try MetadataHeader(File: reader)
        
        contentGroups = []
        for index in 0...63 {
            contentGroups.insert(try MetadataContentGroupEntry(File: reader), at: index)
        }
        
        contentChunks = []
        let chunkCount = Int(contentGroups.map({ $0.chunkCount }).reduce(0, +));
        for index in 0...chunkCount - 1 {
            contentChunks.insert(try MetadataContentChunkEntry(File: reader, DirectoryUrl: url), at: index)
        }
    }
    
//    init(Offset offset: UInt64, File reader: Reader) throws {
//        signature = try Signature(File: reader)
//        header = try MetadataHeader(File: reader)
//        
//        contentGroups = []
//        for index in 0...63 {
//            contentGroups.insert(try MetadataContentGroupEntry(File: reader), at: index)
//        }
//        
//        contentChunks = []
//        let chunkCount = Int(contentGroups.map({ $0.chunkCount }).reduce(0, +));
//        for index in 0...chunkCount {
//            contentChunks.insert(try MetadataContentChunkEntry(PartitionOffset: offset, File: reader), at: index)
//        }
//    }
}
