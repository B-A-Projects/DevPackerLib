//
//  File.swift
//  
//
//  Created by Yannick de Boer on 12/07/2024.
//

import Foundation
import CryptoSwift

/// Represents an entry in the content chunk
/// table of the metadata file. It describes  the
/// properties of a content chunk, such as
/// the **name**, **size** and **type** of chunk.
public struct MetadataContentChunkEntry : Codable {
    
    /// The name of the file this entry represents.
    var chunkFileName: String
    
    /// The URL at which the chunk file or 
    /// associated hash file can be found. This
    /// value is only used for CDN packages.
    var chunkFileUrl: URL?
    
    /// The zero-based index of this entry in the
    /// list of chunk entries.
    var index: UInt16
    
    /// The flags identifying the properties of this
    /// entry. This includes the **content type** and
    /// **hash type** of the entry
    var flags: MetadataContentChunkFlags
    
    /// The size of the content file in bytes.
    var size: UInt64
    
    /// The SHA1 hash computed using either the
    /// **content file** or **content hash file** as
    /// the input.
    ///
    /// Whether the content file or the content
    /// hash file is used depends on the value of the
    /// `flags` property.
    ///
    /// For entries with a **`flags`** value containing
    /// **`NoHash`**, the **.app** file is digested for this hash.
    /// For entries with a **`flags`** value containing
    /// **`Hash`**, the **.h3** file is digested for this hash.
    var hash: [UInt8]
    
    
    /// Creates a new **`MetadataContent
    /// ChunkEntry`** object for an extracted
    /// CDN content chunk that is present in the 
    /// same folder as the title metadata file.
    ///
    /// - Parameters:
    ///     - DirectoryUrl: The URL that points to the directory in 
    ///       which the content chunk can be found.
    ///     - File: The filehandle currently processing the 
    ///       metadata file this chunk is a part of.
    init (File fileHandle: Reader, DirectoryUrl url: URL?) throws {
        let name = String(format:"%02X", try fileHandle.readInteger() as UInt32)
        chunkFileName = String(repeating: "0", count: 8 - name.count) + name
        chunkFileUrl = url//.append(Component: chunkFileName)
        index = try fileHandle.readInteger()
        flags = MetadataContentChunkFlags.Parse(Value: try fileHandle.readInteger())
        size = try fileHandle.readInteger()
        hash = try fileHandle.readUnsignedByteArray(ByteCountToRead: 0x14)
        
        try fileHandle.seek(Offset: min(fileHandle.offset + 0xc, fileHandle.length - 1))
    }
    
//    public func decrypt(DecryptionKey key: [UInt8],
//                        FileOffset offset: UInt64,
//                        FileLength length: UInt64,
//                        File reader: Reader?
//    ) throws -> [UInt8] {
//        
//    }
//    
//    public func decrypt(DecryptionKey key: [UInt8]) throws -> [UInt8] {
//        guard chunkFileUrl != nil else {
//            throw ReadError.InvalidValue
//        }
//        
//        if flags.Value & 0x2 != 0 {
//            return try decryptHashTreeChunk(ChunkPath: chunkFileUrl!.append(Component: "\(chunkFileName).app"),
//                                            HashPath: chunkFileUrl!.append(Component: "\(chunkFileName).h3"),
//                                            DecryptionKey: key)
//        }
//        return try decryptRegularChunk(ChunkPath: chunkFileUrl!.append(Component: "\(chunkFileName).app"),
//                                       DecryptionKey: key)
//    }
//    
//    private func decryptHashTreeChunk(ChunkPath chunkPath: URL,
//                                      HashPath hashPath: URL,
//                                      DecryptionKey key: [UInt8]
//    ) throws -> [UInt8] {
//        return []
//    }
//    
//    private func decryptRegularChunk(ChunkPath chunkPath: URL,
//                                     DecryptionKey key: [UInt8]
//    ) throws -> [UInt8] {
//        var iv = Array.init(repeating: UInt8(0), count: 16)
//        for index in 0...1 {
//            iv[1 - index] = UInt8((index >> (index * 8)) & 0xFF)
//        }
//        
//        let reader = try BinaryReader(Order: .LittleEndian, Path: chunkPath)
//        let data = try reader.readUnsignedByteArray(ByteCountToRead: size)
//        
//        let decryptor = try AES(key: key, blockMode: CBC(iv: iv), padding: .noPadding)
//        return try decryptor.decrypt(data)
//    }
}
