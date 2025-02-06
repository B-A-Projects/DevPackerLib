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
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: FilesystemGroupKeys.self)
        self._index = try container.decode(UInt16.self, forKey: .index)
        self._groupOffset = try container.decode(UInt64.self, forKey: .groupOffset)
        self._groupSize = try container.decode(UInt64.self, forKey: .groupSize)
        self._ownerTitleId = try container.decode(UInt64.self, forKey: .ownerTitleId)
        self._groupId = try container.decode(UInt32.self, forKey: .groupId)
        self._flags = try container.decode(UInt16.self, forKey: .flags)
    }
    
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
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: FilesystemGroupKeys.self)
        try container.encode(_index, forKey: .index)
        try container.encode(_groupOffset, forKey: .groupOffset)
        try container.encode(_groupSize, forKey: .groupSize)
        try container.encode(_ownerTitleId, forKey: .ownerTitleId)
        try container.encode(_groupId, forKey: .groupId)
        try container.encode(_flags, forKey: .flags)
    }
}
