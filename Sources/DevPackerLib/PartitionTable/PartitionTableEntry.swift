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
    
    var offset: UInt64
    
    var partition: PartitionHeader? = nil
    
    public init(File reader: Reader) throws {
        let baseOffset = reader.offset
        partitionName = try reader.readString()
        type = PartitionType.Parse(Value: partitionName)
        
        try reader.seek(Offset: baseOffset + 0x20)
        offset = try reader.readInteger() << 0xF
        try reader.seek(Offset: reader.offset + 0x5C)
    }
    
    internal func parsePartition(File reader: Reader) throws {
        
    }
}
