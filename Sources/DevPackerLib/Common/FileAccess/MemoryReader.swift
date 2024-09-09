//
//  File.swift
//  
//
//  Created by Yannick de Boer on 10/08/2024.
//

import Foundation

public class MemoryReader: Reader {
    
    public var byteOrder: Endianness
    
    /// The current current position of the reader in bytes.
    public var offset: UInt64 { return _offset }
    
    /// The total length of the file in bytes.
    public var length: UInt64 { return _length }
    
    private var _offset: UInt64 = 0
    private var _length: UInt64 = 0
    private var _array: [UInt8]
    
    public init(From byteArray: [UInt8], ByteOrder endianness: Endianness) throws {
        guard !byteArray.isEmpty else {
            throw ReadError.Uninitialized
        }
        
        _array = byteArray
        _length = UInt64(byteArray.count)
        byteOrder = endianness
    }
    
    public func readString(Offset offset: UInt64?, StringEncoding encoding: String.Encoding, IsPeek peek: Bool) throws -> String {
        let startOffset = offset ?? _offset
        
        var readBytes: [UInt8] = []
        for index in startOffset..._length - 1 {
            let character = try read(ByteCountToRead: 1, Offset: index, IsPeek: true)?[0] ?? 0
            guard character != 0x00 else {
                break
            }
            readBytes.insert(character, at: Int(index - startOffset))
        }
        
        if (!peek) {
            _offset = startOffset + UInt64(readBytes.count)
        }
        
        if readBytes.count > 0 {
            return String(bytes: readBytes, encoding: encoding)!
        }
        return String()
    }
    
    public func readBool(Offset offset: UInt64?, IsPeek peek: Bool) throws -> Bool {
        return try (readInteger(ByteOrder: .LittleEndian, Offset: offset, IsPeek: peek) as UInt8) & 0x1 != 0
    }
    
    public func readInteger<T>(ByteOrder byteOrder: Endianness, Offset offset: UInt64?, IsPeek peek: Bool) throws -> T where T : FixedWidthInteger {
        if let buffer = try read(ByteCountToRead: UInt64(T.bitWidth / 8),
                                 Offset: offset,
                                 IsPeek: peek) {
            var value = 0 as T
            if self.byteOrder == .LittleEndian {
                buffer.reversed().forEach { value = (value << 8) | T($0) }
            } else {
                buffer.forEach { value = (value << 8) | T($0) }
            }
            
            if byteOrder == .BigEndian {
                return value.bigEndian
            }
            return value.littleEndian
        }
        return 0 as T
    }
    
    public func readUnsignedByteArray(ByteCountToRead length: UInt64, Offset offset: UInt64?, IsPeek peek: Bool) throws -> [UInt8] {
        if let buffer = try read(ByteCountToRead: length, Offset: offset, IsPeek: peek) {
            return buffer;
        }
        return Array()
    }
    
    public func seek(Offset offset: UInt64) throws {
        guard offset < _length else {
            throw ReadError.InvalidOffset(Offset: offset, Length: _length)
        }
        _offset = offset
    }
    
    private func read(ByteCountToRead length: UInt64, Offset offset: UInt64? = nil, IsPeek isPeek: Bool = false) throws -> [UInt8]? {
        guard !_array.isEmpty else {
            throw ReadError.Uninitialized
        }
        
        let readOffset = offset ?? _offset
        guard readOffset + length < _length else {
            throw ReadError.InvalidReadLength(Offset: readOffset, ReadLength: length, FileLength: _length)
        }
        
        var output: [UInt8] = []
        for byte in 0...length - 1 {
            output.insert(_array[Int(readOffset + byte)], at: Int(byte))
        }
        
        if (!isPeek) {
            _offset = readOffset + length
        }
        return output
    }
}
