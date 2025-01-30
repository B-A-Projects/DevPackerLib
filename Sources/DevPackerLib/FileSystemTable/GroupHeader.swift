//
//  File.swift
//  
//
//  Created by Yannick de Boer on 15/07/2024.
//

import Foundation
import CryptoSwift

public struct FileSystemTableGroupHeader: Codable {
    
    public var index: UInt16 { get { return 0 } }
    
    public var groupOffset: UInt64 { get { return _groupOffset }}
    
    public var groupSize: UInt64 { get { return _groupSize } }
    
    public var flags: UInt16 { get { return _flags } }
    
    public var hasHashTree: Bool { return (flags & 0x440) != 0 }
    
    private var _index: UInt16 = 0
    private var _groupOffset: UInt64 = 0
    private var _groupSize: UInt64 = 0
    private var _ownerTitleId: UInt64 = 0
    private var _groupId: UInt32 = 0
    private var _flags: UInt16 = 0
    
    public init(File reader: Reader,
                Index index: UInt16
    ) throws {
        _index = index
        _groupOffset = UInt64(try reader.readInteger() as UInt32) * 0x8000
        _groupSize = UInt64(try reader.readInteger() as UInt32) * 0x8000
        _ownerTitleId = try reader.readInteger()
        _groupId = try reader.readInteger()
        _flags = try reader.readInteger()
        try reader.seek(Offset: reader.offset + 0xA)
    }
}
