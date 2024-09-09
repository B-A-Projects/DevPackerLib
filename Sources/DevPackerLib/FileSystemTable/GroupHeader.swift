//
//  File.swift
//  
//
//  Created by Yannick de Boer on 15/07/2024.
//

import Foundation
import CryptoSwift

public struct FileSystemTableGroupHeader: Codable {
    
    var index: UInt32
    
    var name: String?
    
    var directory: URL?
    
    var sectorOffset: UInt32
    
    var sectorSize: UInt32
    
    var ownerTitleId: UInt64
    
    var groupId: UInt16
    
    var flags: UInt16
    
    var isSystem: Bool
    
    public init(File reader: Reader,
                Index index: UInt32,
                IsSystemPartition isSystem: Bool,
                DirectoryPath path: URL?
    ) throws {
        self.index = index
        self.isSystem = isSystem
        if directory != nil {
            directory = path
            let indexString = String(format:"%02X", index)
            name = String(repeating: "0", count: 8 - indexString.count) + indexString
        }
        
        sectorOffset = try reader.readInteger()
        sectorSize = try reader.readInteger()
        ownerTitleId = try reader.readInteger()
        groupId = try reader.readInteger()
        flags = try reader.readInteger()
        try reader.seek(Offset: reader.offset + 0xC)
    }
    
    public func Read(FileOffset offset: UInt64,
                     FileLength length: UInt64,
                     File reader: Reader?,
                     DecryptionKey key: [UInt8]?
    ) throws -> [UInt8] {
        var chunkReader: Reader
        if reader != nil {
            chunkReader = reader!
        } else if directory != nil {
            chunkReader = try BinaryReader(Order: .BigEndian, Path: directory!.append(Component: "\(name!).app"))
        } else {
            throw ReadError.FileNotFound
        }
        
        var file: [UInt8] = []
        if key != nil {
            file = try decrypt(File: chunkReader, DecryptionKey: key!, FileOffset: offset, FileLength: length)
        } else {
            try chunkReader.seek(Offset: offset)
            file = try chunkReader.readUnsignedByteArray(ByteCountToRead: length)
        }
        return file
    }
    
    public func decrypt(File reader: Reader,
                        DecryptionKey key: [UInt8],
                        FileOffset offset: UInt64,
                        FileLength length: UInt64
    ) throws -> [UInt8] {
        if flags & 0x440 != 0 {
            return try decryptHashTreeChunk(File: reader,
                                            DecryptionKey: key,
                                            FileOffset: offset,
                                            FileLength: length)
        }
        return try decryptRegularChunk(File: reader,
                                       DecryptionKey: key,
                                       FileOffset: offset,
                                       FileLength: length)
    }
    
    private func decryptHashTreeChunk(File reader: Reader,
                                      DecryptionKey key: [UInt8],
                                      FileOffset offset: UInt64,
                                      FileLength length: UInt64
    ) throws -> [UInt8] {
        return []
    }
    
    private func decryptRegularChunk(File reader: Reader,
                                     DecryptionKey key: [UInt8],
                                     FileOffset offset: UInt64,
                                     FileLength length: UInt64
    ) throws -> [UInt8] {
        let groupOffset = reader.offset + UInt64(sectorOffset * 0x8000)
        try reader.seek(Offset: groupOffset)
        let data = try reader.readUnsignedByteArray(ByteCountToRead: UInt64(sectorSize * 0x8000))
        
        var iv = Array.init(repeating: UInt8(0), count: 16)
        if isSystem {
            let sectorIndex = (groupOffset - 0x10000) / 0x10000
            for index in 0...7 {
                iv[15 - index] = UInt8((groupOffset >> (index * 8)) & 0xFF)
            }
        } else {
            for index in 0...1 {
                iv[1 - index] = UInt8((self.index >> (index * 8)) & 0xFF)
            }
        }
        
        let decryptor = try AES(key: key, blockMode: CBC(iv: iv), padding: .noPadding)
        let decryptedData = try decryptor.decrypt(data)
        
        let memoryReader = try MemoryReader(From: data, ByteOrder: .BigEndian)
        try memoryReader.seek(Offset: offset)
        return try memoryReader.readUnsignedByteArray(ByteCountToRead: length, Offset: 0, IsPeek: false)
    }
}
