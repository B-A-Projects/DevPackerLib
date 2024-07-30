//
//  File.swift
//  
//
//  Created by Yannick de Boer on 27/07/2024.
//

import Foundation

public struct TicketFile: Codable {
    
    var signature: Signature
    
    var primaryHeader: TicketPrimaryHeader
    
    var secondaryHeader: TicketSecondaryHeader
    
    var secondaryHeaderEntries: [TicketSecondarySubheader]
    
    init(File reader: Reader) throws {
        signature = try Signature(File: reader)
        primaryHeader = try TicketPrimaryHeader(File: reader)
        secondaryHeader = try TicketSecondaryHeader(File: reader)
        
        secondaryHeaderEntries = []
        let offset = reader.offset
        for index in 0...secondaryHeader.subheaderCount {
            secondaryHeaderEntries.insert(try TicketSecondarySubheader(File: reader, SecondaryHeaderOffset: offset), at: Int(index))
        }
    }
}
