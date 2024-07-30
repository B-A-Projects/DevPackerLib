//
//  File.swift
//  
//
//  Created by Yannick de Boer on 27/07/2024.
//

import Foundation

public struct TicketPrimaryHeader: Codable {
    
    var ecdhData: [UInt8]
    
    var ticketVersion: UInt8
    
    var titleKey: [UInt8]
    
    var ticketId: UInt64
    
    var consoleId: UInt32
    
    var titleId: UInt64
    
    var titleVersion: UInt16
    
    var titleMaskResult: UInt32
    
    var titleMask: UInt32
    
    var exportAllowed: Bool
    
    var commonKeyType: UInt8
    
    var data: [UInt8]
    
    var permissions: [UInt8]
    
    public init(File reader: Reader) throws {
        ecdhData = try reader.readUnsignedByteArray(ByteCountToRead: 0x3C, Offset: nil, IsPeek: false)
        ticketVersion = try reader.readUnsignedByte(Offset: nil, IsPeek: false)
        titleKey = try reader.readUnsignedByteArray(ByteCountToRead: 0x10, Offset: reader.offset + 0x2, IsPeek: false)
        ticketId = try reader.readUnsignedLong(Offset: reader.offset + 0x1, IsPeek: false)
        consoleId = try reader.readUnsignedInt(Offset: nil, IsPeek: false)
        titleId = try reader.readUnsignedLong(Offset: nil, IsPeek: false)
        titleVersion = try reader.readUnsignedShort(Offset: reader.offset + 0x2, IsPeek: false)
        titleMaskResult = try reader.readUnsignedInt(Offset: nil, IsPeek: false)
        titleMask = try reader.readUnsignedInt(Offset: nil, IsPeek: false)
        exportAllowed = try reader.readBool(Offset: nil, IsPeek: false)
        commonKeyType = try reader.readUnsignedByte(Offset: nil, IsPeek: false)
        data = try reader.readUnsignedByteArray(ByteCountToRead: 0x30, Offset: nil, IsPeek: false)
        permissions = try reader.readUnsignedByteArray(ByteCountToRead: 0x40, Offset: nil, IsPeek: false)
    }
}
