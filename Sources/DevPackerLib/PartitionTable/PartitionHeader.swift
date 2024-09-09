//
//  File.swift
//  
//
//  Created by Yannick de Boer on 13/07/2024.
//

import Foundation

public struct PartitionHeader: Codable {
    
    var filesystemTableOffset: UInt64
    
    var partitionSize: UInt64
    
    var hashBlockSize: UInt32
    
    var hashCount: UInt32
    
    var filesystemTableSize: UInt32
    
    var hashHeaderCount: UInt32
    
    public init(File reader: Reader) throws {
        guard try reader.readInteger() == 0xCC93A4F5 else {
            throw ReadError.InvalidValue
        }
        
        let headerSize: UInt32 = try reader.readInteger()
        filesystemTableOffset = UInt64(headerSize) + reader.offset - 0x8
        
        let size: UInt32 = try reader.readInteger()
        partitionSize = UInt64(size) << 15
        
        hashBlockSize = try reader.readInteger()
        hashCount = try reader.readInteger()
        filesystemTableSize = try reader.readInteger()
        hashHeaderCount = try reader.readInteger()
    }
}
