//
//  Partition.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 24/01/2025.
//

protocol Partition: Codable {
    
    var partitionName: String { get }
    
    var type: PartitionType { get }
    
    var offset: UInt64 { get }
    
    var filesystemTableOffset: UInt64 { get }
    
    var partitionSize: UInt64 { get }
    
    var hashBlockSize: UInt32 { get }
    
    var hashCount: UInt32 { get }
    
    var filesystemTableSize: UInt32 { get }
}
