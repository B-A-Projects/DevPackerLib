//
//  Reader.swift
//  WudConverter
//
//  Created by Yannick de Boer on 15/02/2024.
//

import Foundation

public protocol Reader {
    func open() throws
    func close() throws
    
    func seek(Offset offset: UInt64) throws
    func readUnsignedByteArray(ByteCountToRead length: UInt64, Offset offset: UInt64?, IsPeek peek: Bool) throws -> [UInt8]
    func readUnsignedByte(Offset offset: UInt64?, IsPeek peek: Bool) throws -> UInt8
    func readUnsignedShort(Offset offset: UInt64?, IsPeek peek: Bool) throws -> UInt16
    func readUnsignedInt(Offset offset: UInt64?, IsPeek peek: Bool) throws -> UInt32
    func readUnsignedLong(Offset offset: UInt64?, IsPeek peek: Bool) throws -> UInt64
    func readByte(Offset offset: UInt64?, IsPeek peek: Bool) throws -> Int8
    func readShort(Offset offset: UInt64?, IsPeek peek: Bool) throws -> Int16
    func readInt(Offset offset: UInt64?, IsPeek peek: Bool) throws -> Int32
    func readLong(Offset offset: UInt64?, IsPeek peek: Bool) throws -> Int64
    func readBool(Offset offset: UInt64?, IsPeek peek: Bool) throws -> Bool
    func readString(Offset offset: UInt64?, StringEncoding encoding: String.Encoding, IsPeek peek: Bool) throws -> String
    //func readString(ByteCountToRead length: UInt64, Offset offset: UInt64?, StringEncoding encoding: String.Encoding) throws -> String
    
    var byteOrder: Endianness { get }
    var filePath: URL { get }
    var offset: UInt64 { get }
}
