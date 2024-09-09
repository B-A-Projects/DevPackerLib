//
//  File.swift
//  
//
//  Created by Yannick de Boer on 13/07/2024.
//

import Foundation

public struct PartitionTableHeader: Codable {
    
    var partitionSectorOffset: UInt64
    
    var partitionCount: UInt32
    
    var partitions: [PartitionTableEntry]
    
    public init(File reader: Reader) throws {
        guard try reader.readInteger() == 0xCCA6E67B else {
            throw ReadError.InvalidValue
        }
        
        let headerSize: UInt32 = try reader.readInteger()
        partitionSectorOffset = UInt64(headerSize) + reader.offset - 0x8
        
        try reader.seek(Offset: reader.offset + 0x14)
        partitionCount = try reader.readInteger()
        
        partitions = []
        try reader.seek(Offset: reader.offset + 0x7E0)
        for index in 0...partitionCount {
            partitions.insert(try PartitionTableEntry(File: reader), at: Int(index))
        }
    }
}
