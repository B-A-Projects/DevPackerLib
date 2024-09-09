//
//  File.swift
//  
//
//  Created by Yannick de Boer on 22/07/2024.
//

import Foundation
import CryptoSwift

/// Represents an installable content package
/// as delivered from the Wii U E-shop CDN.
public struct CdnPackage: Codable {
    
    public var directoryUrl: URL
    
    public var metadata: Metadata
    
    public var ticket: Ticket
    
    //public var fileSystems: [FilesystemTableHeader]
    
    public var fileSystem: FilesystemTableHeader
    
    //internal var partitionTable: PartitionTableHeader?
    
    //internal var partitionHeaders: [PartitionHeader]?
    
    public init(Directory url: URL, DecryptionKey key: [UInt8]) throws {
        directoryUrl = url
        ticket = try Ticket(DirectoryUrl: directoryUrl)
        metadata = try Metadata(DirectoryUrl: directoryUrl)
        
        let decryptionKey = try ticket.getDecryptionKey(DecryptionKey: key)
        let iv = Array.init(repeating: UInt8(0), count: 16)
        
        let reader = try BinaryReader(Order: .BigEndian, Path: url.append(Component: "00000000.app"))
        let encryptedData = try reader.readUnsignedByteArray(ByteCountToRead: reader.length)
        
        let decryptor = try AES(key: decryptionKey, blockMode: CBC(iv: iv), padding: .noPadding)
        let decryptedData = try decryptor.decrypt(encryptedData)
        
        //fileSystems = []
        let filesystemReader = try MemoryReader(From: decryptedData, ByteOrder: .BigEndian)
        fileSystem = try FilesystemTableHeader(PartitionName: "0", File: filesystemReader, DirectoryPath: url)
        //fileSystems.insert(try FilesystemTableHeader(PartitionName: "0", File: filesystemReader, DirectoryPath: url), at: 0)
    }
}
