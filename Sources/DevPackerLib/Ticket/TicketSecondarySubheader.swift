//
//  File.swift
//  
//
//  Created by Yannick de Boer on 27/07/2024.
//

import Foundation

public struct TicketSecondarySubheader: Codable {
    
    var dataOffset: UInt32
    
    var dataChunkCount: UInt32
    
    var dataChunkSize: UInt32
    
    var entrySize: UInt32
    
    var entryType: UInt16
    
    var flags: UInt16
    
    var data: [[UInt8]]
    
    public init(File reader: Reader, SecondaryHeaderOffset offset: UInt64) throws {
        dataOffset = try reader.readUnsignedInt(Offset: nil, IsPeek: false)
        dataChunkCount = try reader.readUnsignedInt(Offset: nil, IsPeek: false)
        dataChunkSize = try reader.readUnsignedInt(Offset: nil, IsPeek: false)
        entrySize = try reader.readUnsignedInt(Offset: nil, IsPeek: false)
        entryType = try reader.readUnsignedShort(Offset: nil, IsPeek: false)
        flags = try reader.readUnsignedShort(Offset: nil, IsPeek: false)
        
        data = []
        for chunk in 0...dataChunkCount {
            data[Int(chunk)] = try reader.readUnsignedByteArray(
                ByteCountToRead: UInt64(dataChunkSize),
                Offset: offset + UInt64(dataOffset) + UInt64(chunk * entrySize),
                IsPeek: true)
        }
    }
}
