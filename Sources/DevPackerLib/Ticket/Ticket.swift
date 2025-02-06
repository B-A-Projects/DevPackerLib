//
//  File.swift
//  
//
//  Created by Yannick de Boer on 27/07/2024.
//

import Foundation
import CryptoSwift

public struct Ticket: Codable {
    
    var signature: Signature
    
    var primaryHeader: TicketPrimaryHeader
    
    var secondaryHeader: TicketSecondaryHeader
    
    var secondaryHeaderEntries: [TicketSecondaryHeaderEntry]
    
    init(File reader: Reader, DecryptionKey key: [UInt8]) throws {
        signature = try Signature(File: reader)
        primaryHeader = try TicketPrimaryHeader(File: reader, DecryptionKey: key)
        secondaryHeader = try TicketSecondaryHeader(File: reader)
        
        secondaryHeaderEntries = []
        let offset = reader.offset
        for index in 0...secondaryHeader.subheaderCount {
            secondaryHeaderEntries.insert(try TicketSecondaryHeaderEntry(File: reader, SecondaryHeaderOffset: offset), at: Int(index))
        }
    }
}
