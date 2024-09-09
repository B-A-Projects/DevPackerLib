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
        ecdhData = try reader.readUnsignedByteArray(ByteCountToRead: 0x3C)
        ticketVersion = try reader.readInteger()
        titleKey = try reader.readUnsignedByteArray(ByteCountToRead: 0x10, Offset: reader.offset + 0x2)
        ticketId = try reader.readInteger(Offset: reader.offset + 0x1)
        consoleId = try reader.readInteger()
        titleId = try reader.readInteger()
        titleVersion = try reader.readInteger(Offset: reader.offset + 0x2)
        titleMaskResult = try reader.readInteger()
        titleMask = try reader.readInteger()
        exportAllowed = try reader.readBool()
        commonKeyType = try reader.readInteger()
        data = try reader.readUnsignedByteArray(ByteCountToRead: 0x30)
        permissions = try reader.readUnsignedByteArray(ByteCountToRead: 0x40)
    }
}
