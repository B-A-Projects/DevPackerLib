//
//  File.swift
//  
//
//  Created by Yannick de Boer on 22/07/2024.
//

import Foundation

/// Represents an installable content package
/// as delivered from the Wii U E-shop CDN.
@available(macOS 10.15.4, *)
public struct CdnPackage: Codable {
    
    public var directoryUrl: URL
    
    public var metadata: MetadataFile
    
    public init(Directory url: URL) throws {
        directoryUrl = url
        
        var metadataUrl: URL
        if #available(macOS 13.0, *) {
            metadataUrl = url.appending(component: "title.tmd")
        } else {
            metadataUrl = url.appendingPathComponent( "title.tmd")
        }
        
        //let reader = BinaryReader(Order: .BigEndian, Path: directoryPath + "title.tmd")
        let reader = BinaryReader(Order: .BigEndian, Path: metadataUrl)
        try reader.open()
        metadata = try MetadataFile(File: reader)
        try reader.close()
    }
}
