//
//  Reader.swift
//  WudConverter
//
//  Created by Yannick de Boer on 15/02/2024.
//

import Foundation

public protocol Reader {
    func seek(Offset offset: UInt64) throws
    func readUnsignedByteArray(ByteCountToRead length: UInt64, Offset offset: UInt64?, IsPeek peek: Bool) throws -> [UInt8]
    func readInteger<T: FixedWidthInteger>(ByteOrder byteOrder: Endianness, Offset offset: UInt64?, IsPeek peek: Bool) throws -> T
    func readBool(Offset offset: UInt64?, IsPeek peek: Bool) throws -> Bool
    func readString(Offset offset: UInt64?, StringEncoding encoding: String.Encoding, IsPeek peek: Bool) throws -> String
    
    var byteOrder: Endianness { get }
    var offset: UInt64 { get }
    var length: UInt64 { get }
}


extension Reader {
    func readInteger<T: FixedWidthInteger>() throws -> T {
        return try readInteger(ByteOrder: .LittleEndian, Offset: nil, IsPeek: false)
    }
    
    func readInteger<T: FixedWidthInteger>(ByteOrder byteOrder: Endianness) throws -> T {
        return try readInteger(ByteOrder: byteOrder, Offset: nil, IsPeek: false)
    }
    
    func readInteger<T: FixedWidthInteger>(Offset offset: UInt64) throws -> T {
        return try readInteger(ByteOrder: .LittleEndian, Offset: offset, IsPeek: false)
    }
    
    func readInteger<T: FixedWidthInteger>(ByteOrder byteOrder: Endianness, Offset offset: UInt64) throws -> T {
        return try readInteger(ByteOrder: byteOrder, Offset: offset, IsPeek: false)
    }
    
    func readInteger<T: FixedWidthInteger>(Offset offset: UInt64, IsPeek peek: Bool) throws -> T {
        return try readInteger(ByteOrder: .LittleEndian, Offset: offset, IsPeek: peek)
    }
    
    func readUnsignedByteArray(ByteCountToRead length: UInt64) throws -> [UInt8] {
        return try readUnsignedByteArray(ByteCountToRead: length, Offset: nil, IsPeek: false)
    }
    
    func readUnsignedByteArray(ByteCountToRead length: UInt64, Offset offset: UInt64) throws -> [UInt8] {
        return try readUnsignedByteArray(ByteCountToRead: length, Offset: offset, IsPeek: false)
    }
    
    func readBool() throws -> Bool {
        return try readBool(Offset: nil, IsPeek: false)
    }
    
    func readBool(Offset offset: UInt64) throws -> Bool {
        return try readBool(Offset: offset, IsPeek: false)
    }
    
    func readString() throws -> String {
        return try readString(Offset: nil, StringEncoding: String.Encoding.utf8, IsPeek: false)
    }
    
    func readString(Offset offset: UInt64) throws -> String {
        return try readString(Offset: offset, StringEncoding: String.Encoding.utf8, IsPeek: false)
    }
    
    func readString(Offset offset: UInt64, IsPeek peek: Bool) throws -> String {
        return try readString(Offset: offset, StringEncoding: String.Encoding.utf8, IsPeek: peek)
    }
    
    func readString(Offset offset: UInt64, StringEncoding encoding: String.Encoding) throws -> String {
        return try readString(Offset: offset, StringEncoding: encoding, IsPeek: false)
    }
}
