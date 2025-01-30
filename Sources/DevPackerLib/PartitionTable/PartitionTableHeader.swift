//
//  File.swift
//  
//
//  Created by Yannick de Boer on 13/07/2024.
//

import Foundation
import CryptoSwift

public struct PartitionTableHeader: Codable {
    
    var partitionCount: UInt32
    
    var tableEntries: [PartitionTableEntry]
    
    public init(File reader: Reader, Decryptor aes: AES? = nil) throws {
        var tableBytes = try reader.readUnsignedByteArray(ByteCountToRead: 0x8000, Offset: 0x18000)
        
        var tableReader: Reader
        if aes != nil {
            tableReader = try MemoryReader(From: try aes!.decrypt(tableBytes), ByteOrder: .BigEndian)
        } else {
            tableReader = try MemoryReader(From: tableBytes, ByteOrder: .BigEndian)
        }
        
        guard try tableReader.readInteger() == 0xCCA6E67B else {
            throw ReadError.InvalidValue
        }
        
        let headerSize: UInt32 = try tableReader.readInteger()
        
        try tableReader.seek(Offset: tableReader.offset + 0x14)
        partitionCount = try tableReader.readInteger()
        
        tableEntries = []
        try tableReader.seek(Offset: tableReader.offset + 0x7E0)
        for index in 0...partitionCount {
            tableEntries.insert(try PartitionTableEntry(File: tableReader), at: Int(index))
        }
        
//        for entry in tableEntries {
//            var headerBytes = try reader.readUnsignedByteArray(ByteCountToRead: 0x8000, Offset: entry.offset)
//            
//            var headerReader: Reader
//            if aes != nil {
//                headerReader = try MemoryReader(From: try aes!.decrypt(headerBytes), ByteOrder: .BigEndian)
//            } else {
//                headerReader = try MemoryReader(From: tableBytes, ByteOrder: .BigEndian)
//            }
//            try entry.parsePartition(File: headerReader)
//        }
    }
}
