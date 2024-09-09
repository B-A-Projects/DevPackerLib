//
//  File.swift
//  
//
//  Created by Yannick de Boer on 13/07/2024.
//

import Foundation

public struct PartitionTableEntry: Codable {
    
    var partitionName: String
    
    var type: PartitionType
    
    var size: UInt64
    
    var offset: UInt64
    
    public init(File reader: Reader) throws {
        let baseOffset = reader.offset
        partitionName = try reader.readString()
        type = PartitionType.Parse(Value: partitionName)
        
        try reader.seek(Offset: baseOffset + 0x20)
        size = try reader.readInteger()
        offset = size + 0x20000
        try reader.seek(Offset: reader.offset + 0x5C)
    }
}
