//
//  File.swift
//  
//
//  Created by Yannick de Boer on 27/07/2024.
//

import Foundation

public struct TicketSecondaryHeaderEntry: Codable {
    
    var dataOffset: UInt32
    
    var dataChunkCount: UInt32
    
    var dataChunkSize: UInt32
    
    var entrySize: UInt32
    
    var entryType: UInt16
    
    var flags: UInt16
    
    var data: [[UInt8]]
    
    public init(File reader: Reader, SecondaryHeaderOffset offset: UInt64) throws {
        dataOffset = try reader.readInteger()
        dataChunkCount = try reader.readInteger()
        dataChunkSize = try reader.readInteger()
        entrySize = try reader.readInteger()
        entryType = try reader.readInteger()
        flags = try reader.readInteger()
        
        data = []
        guard dataChunkCount > 0 else {
            return
        }
        
        for chunk in 0...dataChunkCount - 1 {
            data[Int(chunk)] = try reader.readUnsignedByteArray(
                ByteCountToRead: UInt64(dataChunkSize),
                Offset: offset + UInt64(dataOffset) + UInt64(chunk * entrySize),
                IsPeek: true)
        }
    }
}
