//
//  BinaryReader.swift
//  WudConverter
//
//  Created by Yannick de Boer on 15/02/2024.
//

import Foundation

@available(macOS 10.15.4, *)
public class BinaryReader: Reader {
    public var byteOrder: Endianness
    public var filePath: URL
    public var offset: UInt64 { return _offset }
    
    private var _fileHandle: FileHandle?
    private var _offset: UInt64 = 0
    private var _length: UInt64 = 0
    
    public init(Order order: Endianness, Path path: URL)
    {
        byteOrder = order
        filePath = path
    }
    
    deinit {
        do {
            try close()
        }
        catch {
            
        }
    }
    
    public func open() throws {
        if _fileHandle == nil {
            _fileHandle = try FileHandle(forReadingFrom: filePath)
        }
        
        guard _fileHandle != nil else {
            throw ReadError.FileInitFailed
        }
        
        if let length = try _fileHandle?.seekToEnd() {
            _length = length
        }
        try _fileHandle?.seek(toOffset: 0)
    }
    
    public func close() throws {
        if _fileHandle != nil {
            try _fileHandle?.close()
            _fileHandle = nil;
        }
    }
    
    public func seek(Offset offset: UInt64) throws {
        guard offset < _length else {
            throw ReadError.InvalidOffset(Offset: offset, Length: _length)
        }
        try _fileHandle?.seek(toOffset: offset)
        _offset = offset;
    }
    
    public func readUnsignedByteArray(ByteCountToRead length: UInt64, 
                                      Offset offset: UInt64? = nil,
                                      IsPeek peek: Bool = false
    ) throws -> [UInt8] {
        if let buffer = try read(ByteCountToRead: length, Offset: offset, IsPeek: peek) {
            return buffer;
        }
        return Array()
    }
    
    public func readUnsignedByte(Offset offset: UInt64? = nil,
                                 IsPeek peek: Bool = false
    ) throws -> UInt8 {
        if let buffer = try read(ByteCountToRead: 1, Offset: offset, IsPeek: peek) {
            return buffer[0];
        }
        return 0
    }
    
    public func readUnsignedShort(Offset offset: UInt64? = nil,
                                  IsPeek peek: Bool = false
    ) throws -> UInt16 {
        if let buffer = try read(ByteCountToRead: 2, Offset: offset, IsPeek: peek) {
            return try toUInt16(InputArray: buffer);
        }
        return 0
    }
    
    public func readUnsignedInt(Offset offset: UInt64? = nil,
                                IsPeek peek: Bool = false
    ) throws -> UInt32 {
        if let buffer = try read(ByteCountToRead: 4, Offset: offset, IsPeek: peek) {
            return try toUInt32(InputArray: buffer);
        }
        return 0
    }
    
    public func readUnsignedLong(Offset offset: UInt64? = nil,
                                 IsPeek peek: Bool = false
    ) throws -> UInt64 {
        if let buffer = try read(ByteCountToRead: 8, Offset: offset, IsPeek: peek) {
            return try toUInt64(InputArray: buffer);
        }
        return 0
    }
    
    public func readByte(Offset offset: UInt64? = nil,
                         IsPeek peek: Bool = false
    ) throws -> Int8 {
        if let Buffer = try read(ByteCountToRead: 1, Offset: offset, IsPeek: peek) {
            return Int8(Buffer[0]);
        }
        return 0
    }
    
    public func readShort(Offset offset: UInt64? = nil,
                          IsPeek peek: Bool = false
    ) throws -> Int16 {
        if let buffer = try read(ByteCountToRead: 2, Offset: offset, IsPeek: peek) {
            return try Int16(toUInt16(InputArray: buffer));
        }
        return 0
    }
    
    public func readInt(Offset offset: UInt64? = nil,
                        IsPeek peek: Bool = false
    ) throws -> Int32 {
        if let buffer = try read(ByteCountToRead: 4, Offset: offset, IsPeek: peek) {
            return try Int32(toUInt32(InputArray: buffer));
        }
        return 0
    }
    
    public func readLong(Offset offset: UInt64? = nil,
                         IsPeek peek: Bool = false
    ) throws -> Int64 {
        if let buffer = try read(ByteCountToRead: 8, Offset: offset, IsPeek: peek) {
            return try Int64(toUInt64(InputArray: buffer));
        }
        return 0
    }
    
    public func readBool(Offset offset: UInt64? = nil,
                         IsPeek peek: Bool = false
    ) throws -> Bool {
        return try readUnsignedByte(Offset: offset, IsPeek: peek) & 0x1 != 0
    }
    
    public func readString(Offset offset: UInt64? = nil,
                           StringEncoding encoding: String.Encoding = String.Encoding.utf8,
                           IsPeek peek: Bool = false)
    throws -> String {
        if offset != nil {
            try seek(Offset: offset!)
            if !peek {
                _offset = offset!
            }
        }
        let startOffset = offset ?? _offset
        
        var readBytes: [UInt8] = []
        for index in startOffset..._length {
            let character = try _fileHandle?.read(upToCount: 1)?.map { $0 }[0]
            guard character != nil && character != 0x00 else {
                break
            }
            readBytes.insert(character!, at: Int(index - startOffset))
        }
        
        if (peek) {
            try seek(Offset: _offset)
        } else {
            _offset += UInt64(readBytes.count + 1)
        }
        return String(bytes: readBytes, encoding: encoding)!
    }
    
//    public func readString(ByteCountToRead length: UInt64,
//                           Offset offset: UInt64? = nil,
//                           StringEncoding encoding: String.Encoding = String.Encoding.utf8)
//    throws -> String {
//        guard length > 0 else {
//            throw ReadError.InvalidStringLength
//        }
//        //Enforce max string read length?
//        
//        if offset != nil {
//            try seek(Offset: offset!)
//        }
//        
//        let readBytes = try readUnsignedByteArray(ByteCountToRead: length)
//        var actualLength = 0;
//        while readBytes[actualLength] != 0 && actualLength <= length {
//            actualLength += 1
//        }
//        
//        if actualLength == 0 {
//            return String()
//        }
//        return String(bytes: readBytes[..<actualLength], encoding: encoding)!
//    }
    
    private func toUInt16(InputArray data: [UInt8]) throws -> UInt16 {
        guard data.count == 2 else {
            throw ReadError.InvalidValueLength(ExpectedValueLength: 2, ActualValueLength: UInt64(data.count))
        }
        
        switch byteOrder {
        case Endianness.LittleEndian:
            return UInt16(data[1]) << 8 | UInt16(data[0])
        default:
            return UInt16(data[0]) << 8 | UInt16(data[1])
        }
    }
    
    private func toUInt32(InputArray data: [UInt8]) throws -> UInt32 {
        guard data.count == 4 else {
            throw ReadError.InvalidValueLength(ExpectedValueLength: 4, ActualValueLength: UInt64(data.count))
        }
        
        switch byteOrder {
        case Endianness.LittleEndian:
            return try UInt32(toUInt16(InputArray: Array(data[2...]))) << 16 | UInt32(toUInt16(InputArray: Array(data[..<2])))
        default:
            return try UInt32(toUInt16(InputArray: Array(data[..<2]))) << 16 | UInt32(toUInt16(InputArray: Array(data[2...])))
        }
    }
    
    private func toUInt64(InputArray data: [UInt8]) throws -> UInt64 {
        guard data.count == 8 else {
            throw ReadError.InvalidValueLength(ExpectedValueLength: 8, ActualValueLength: UInt64(data.count))
        }
        
        switch byteOrder {
        case Endianness.LittleEndian:
            return try UInt64(toUInt32(InputArray: Array(data[4...]))) << 32 | UInt64(toUInt32(InputArray: Array(data[..<4])))
        default:
            return try UInt64(toUInt32(InputArray: Array(data[..<4]))) << 32 | UInt64(toUInt32(InputArray: Array(data[4...])))
        }
    }
    
    private func isInBounds(LengthInBytes length: UInt64, Offset offset: UInt64? = nil) -> Bool {
        let currentOffset = offset ?? _offset
        
        if (currentOffset + length > _length) {
            return false
        }
        return true
    }
    
    private func read(ByteCountToRead length: UInt64, Offset offset: UInt64? = nil, IsPeek isPeek: Bool = false) throws -> [UInt8]? {
        guard _fileHandle != nil else {
            throw ReadError.Uninitialized
        }
        
        guard isInBounds(LengthInBytes: length, Offset: offset) else {
            throw ReadError.InvalidReadLength(Offset: offset!, ReadLength: length, FileLength: _length)
        }
        
        if offset != nil {
            try seek(Offset: offset!)
            if !isPeek {
                _offset = offset!
            }
        }
        
        let output = try _fileHandle?.read(upToCount: Int(length))?.map { $0 }
        
        if (isPeek) {
            try seek(Offset: _offset)
        } else {
            _offset += length
        }
        return output
    }
    
//    private func Read(Offset offset: UInt64? = nil, ByteCountToRead length: UInt64) throws -> [UInt8]? {
//        guard _fileHandle != nil else {
//            throw ReadError.Uninitialized
//        }
//        
//        if offset != nil {
//            try seek(Offset: offset!)
//        }
//        
//        let readLength = Int(min(length, (_length - _offset) + 1))
//        if readLength > 0 {
//            var output = try _fileHandle?.read(upToCount: readLength)?.map { $0 }
//            _offset += UInt64(readLength)
//            return output;
//        }
//        return nil
//    }
}
