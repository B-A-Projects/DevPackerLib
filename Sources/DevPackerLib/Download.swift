//
//  Disc 2.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 24/01/2025.
//


import Foundation
import CryptoSwift

struct Download: WiiUGame {
    
    public var titleKey: String
    
    public var name: String
    
    public var consoleType: ConsoleType
    
    public var mediaType: MediaType
    
    public var partitions: [Partition]
    
    public init(Directory url: URL, TitleKey key: String, ConsoleType type: ConsoleType) throws {
        mediaType = .Disc
        consoleType = type
        titleKey = key
        
        let wudUrl = url.append(Component: "game.wud")
        guard wudUrl.fileExists() else {
            throw ReadError.FileNotFound
        }
        
        var reader = try BinaryReader(Order: .BigEndian, Path: wudUrl)
        name = try reader.readString()
        
        var tableReader: Reader
        if try reader.readInteger(Offset: 0x18000) as UInt32 == 0xCCA6E67B {
            var tableBytes = try reader.readUnsignedByteArray(ByteCountToRead: 0x8000, Offset: 0x18000)
            tableReader = try MemoryReader(From: tableBytes, ByteOrder: .BigEndian)
            consoleType = ConsoleType.Development
        } else {
            var tableBytes = try reader.readUnsignedByteArray(ByteCountToRead: 0x8000, Offset: 0x18000)
            var decryptor = try AES(key: titleKey, iv: String(repeating: "0", count: 0x10), padding: .noPadding)
            tableReader = try MemoryReader(From: try decryptor.decrypt(tableBytes), ByteOrder: .BigEndian)
            consoleType = ConsoleType.Retail
        }
        
        guard try tableReader.readInteger() == 0xCCA6E67B else {
            throw ReadError.InvalidValue
        }
        
        let headerSize: UInt32 = try tableReader.readInteger()
        
        try tableReader.seek(Offset: tableReader.offset + 0x14)
        let partitionCount = try tableReader.readInteger() as UInt32
        
        partitions = []
        try tableReader.seek(Offset: tableReader.offset + 0x7E0)
        for index in 0...partitionCount {
            partitions.insert(try DiscPartition(File: tableReader), at: Int(index))
        }
    }
    
    
}
