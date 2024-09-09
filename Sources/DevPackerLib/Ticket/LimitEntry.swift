//
//  File.swift
//  
//
//  Created by Yannick de Boer on 27/07/2024.
//

import Foundation

public struct TicketLimitEntry: Codable {
    
    var limitType: TicketLimitType
    
    var limitSize: UInt32
    
    public init(File reader: Reader) throws {
        limitType = TicketLimitType.Parse(Value: try reader.readInteger())
        limitSize = try reader.readInteger()
    }
}
