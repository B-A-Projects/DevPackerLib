//
//  File.swift
//  
//
//  Created by Yannick de Boer on 12/07/2024.
//

import Foundation

/// Represents an entry in the content chunk
/// table of the metadata file. It describes  the
/// properties of a content chunk, such as
/// the **name**, **size** and **type** of chunk.
public struct MetadataContentChunkEntry : Codable {
    
    /// The name of the file this entry represents.
    var chunkFileName: String
    
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
    /// **`NoHash`**, the **.app** file is used.
    /// For entries with a **`flags`** value containing
    /// **`Hash`**, the **.h3** file is used.
    var hash: [UInt8]
    
    init (File fileHandle: Reader) throws {
        chunkFileName = String(format:"%02X", try fileHandle.readUnsignedInt(Offset: nil, IsPeek: false))
        index = try fileHandle.readUnsignedShort(Offset: nil, IsPeek: false)
        flags = MetadataContentChunkFlags.Parse(Value: try fileHandle.readUnsignedShort(Offset: nil, IsPeek: false))
        size = try fileHandle.readUnsignedLong(Offset: nil, IsPeek: false)
        hash = try fileHandle.readUnsignedByteArray(ByteCountToRead: 0x14, Offset: nil, IsPeek: false)
        
        try fileHandle.seek(Offset: fileHandle.offset + 0xc)
    }
    
    public func decrypt(DirectoryPath path: URL, DecryptionKey key: [UInt8]) throws {
    }
}
