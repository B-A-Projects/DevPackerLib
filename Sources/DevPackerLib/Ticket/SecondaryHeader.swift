//
//  File.swift
//  
//
//  Created by Yannick de Boer on 27/07/2024.
//

import Foundation

public struct TicketSecondaryHeader: Codable {
    
    var version: UInt16
    
    var headerSize: UInt16
    
    var sectionSize: UInt32
    
    var subheaderCount: UInt16
    
    var subheaderSize: UInt16
    
    var flags: UInt32
    
    public init(File reader: Reader) throws {
        version = try reader.readInteger()
        headerSize = try reader.readInteger()
        sectionSize = try reader.readInteger()
        subheaderCount = try reader.readInteger()
        subheaderSize = try reader.readInteger()
        flags = try reader.readInteger()
    }
}
