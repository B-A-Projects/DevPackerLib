//
//  BinaryReader.swift
//  WudConverter
//
//  Created by Yannick de Boer on 15/02/2024.
//

import Foundation


public class BinaryReader: Reader {
    
    /// The byte order in which numerical values are expected to be read from the file.
    public var byteOrder: Endianness
    
    /// The current current position of the reader in bytes.
    public var offset: UInt64 { return _offset }
    
    /// The total length of the file in bytes.
    public var length: UInt64 { return _length }
    
    private var _filePath: URL
    private var _fileHandle: FileHandle?
    private var _offset: UInt64 = 0
    private var _length: UInt64 = 0
    
    public init(Order order: Endianness, Path path: URL) throws
    {
        byteOrder = order
        _filePath = path
        
        if _fileHandle == nil {
            _fileHandle = try FileHandle(forReadingFrom: _filePath)
        }
        
        guard _fileHandle != nil else {
            throw ReadError.FileInitFailed
        }
        
        if let length = try seekToEnd() {
            _length = length
        }
        try seek(Offset: 0)
    }
    
    deinit {
        do {
            if #available(macOS 10.15, *) {
                try _fileHandle?.close()
            } else {
                _fileHandle?.closeFile()
            }
        }
        catch {
            
        }
    }
    
    public func seek(Offset offset: UInt64) throws {
        guard offset < _length else {
            throw ReadError.InvalidOffset(Offset: offset, Length: _length)
        }
        if #available(macOS 10.15, *) {
            try _fileHandle?.seek(toOffset: offset)
        } else {
            _fileHandle?.seek(toFileOffset: offset)
        }
        _offset = offset;
    }
    
    private func seekToEnd() throws -> UInt64? {
        var length: UInt64?
        if #available(macOS 10.15.4, *) {
            length = try _fileHandle?.seekToEnd()
        } else {
            length = _fileHandle?.seekToEndOfFile()
        }
        return length
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
    
    public func readInteger<T: FixedWidthInteger>(ByteOrder byteOrder: Endianness,
                               Offset offset: UInt64? = nil,
                               IsPeek peek: Bool = false
    ) throws -> T {
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
    
    public func readUnsignedByte(Offset offset: UInt64? = nil,
                                 IsPeek peek: Bool = false
    ) throws -> UInt8 {
        if let buffer = try read(ByteCountToRead: 1, Offset: offset, IsPeek: peek) {
            return buffer[0];
        }
        return 0
    }
    
    public func readBool(Offset offset: UInt64? = nil,
                         IsPeek peek: Bool = false
    ) throws -> Bool {
        return try (readInteger(ByteOrder: .LittleEndian, Offset: offset, IsPeek: peek) as UInt8) & 0x1 != 0
    }
    
    public func readString(Offset offset: UInt64? = nil,
                           StringEncoding encoding: String.Encoding = String.Encoding.utf8,
                           IsPeek peek: Bool = false)
    throws -> String {
        let startOffset = offset ?? _offset
        if startOffset != _offset {
            try seek(Offset: startOffset)
            if !peek {
                _offset = startOffset
            }
        }
        
        var readBytes: [UInt8] = []
        for index in startOffset..._length {
            let character = try readInteger(ByteOrder: .LittleEndian) as UInt8
            guard character != 0x00 else {
                break
            }
            readBytes.insert(character, at: Int(index - startOffset))
        }
        
        if (peek) {
            try seek(Offset: _offset)
        } else {
            _offset += UInt64(readBytes.count + 1)
        }
        
        if readBytes.count > 0 {
            return String(bytes: readBytes, encoding: encoding)!
        }
        return String()
    }
    
    private func read(ByteCountToRead length: UInt64, Offset offset: UInt64? = nil, IsPeek isPeek: Bool = false) throws -> [UInt8]? {
        guard _fileHandle != nil else {
            throw ReadError.Uninitialized
        }
        
        let readOffset = offset ?? _offset
        guard readOffset + length <= _length else {
            throw ReadError.InvalidReadLength(Offset: readOffset, ReadLength: length, FileLength: _length)
        }
        
        if readOffset != _offset {
            try seek(Offset: readOffset)
            if !isPeek {
                _offset = readOffset
            }
        }
        
        var output: [UInt8]?
        if #available(macOS 10.15.4, *) {
            output = try _fileHandle?.read(upToCount: Int(length))?.map { $0 }
        } else {
            output = _fileHandle?.readData(ofLength: Int(length)).map { $0 }
        }
        
        if (isPeek) {
            try seek(Offset: _offset)
        } else {
            _offset += length
        }
        return output
    }
}
