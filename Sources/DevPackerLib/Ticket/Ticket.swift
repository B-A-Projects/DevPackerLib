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
    
    init(DirectoryUrl url: URL) throws {
        let ticketUrl = url.append(Component: "title.tik")
        
        let reader = try BinaryReader(Order: .BigEndian, Path: ticketUrl)
        signature = try Signature(File: reader)
        primaryHeader = try TicketPrimaryHeader(File: reader)
        secondaryHeader = try TicketSecondaryHeader(File: reader)
        
        secondaryHeaderEntries = []
        let offset = reader.offset
        for index in 0...secondaryHeader.subheaderCount {
            secondaryHeaderEntries.insert(try TicketSecondaryHeaderEntry(File: reader, SecondaryHeaderOffset: offset), at: Int(index))
        }
    }
    
    public func getDecryptionKey(DecryptionKey key: [UInt8]) throws -> [UInt8] {
        var iv = Array.init(repeating: UInt8(0), count: 16)
        for index in 0...7 {
            iv[7 - index] = UInt8((primaryHeader.titleId >> (index * 8)) & 0xFF)
        }
        
        let encryptor = try AES(key: key,                                    
                                blockMode: CBC(iv: iv),
                                padding: .noPadding)
        return try encryptor.decrypt(primaryHeader.titleKey)
    }
}
