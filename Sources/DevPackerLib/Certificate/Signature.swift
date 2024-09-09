//
//  MetadataSignature.swift
//  
//
//  Created by Yannick de Boer on 12/07/2024.
//

import Foundation

/// Represents the signature of the ticket or
/// metadata file.  In the ticket file, this
/// signature covers the remainder of the file.
/// In the metadata file, this signature covers
/// the entirety of the **`MetadataHeader`**
/// structure.
public struct Signature: Codable {
    
    /// Represents the type of signature.
    var signatureType: SignatureType
    
    /// Represents the metadata signature.
    var signature: [UInt8]
    
    /// Contains the name of the entity that 
    /// signed this title metadata file.
    var signer: String
    
    public init (File fileHandle: Reader) throws {
        signatureType = SignatureType.Parse(Value: try fileHandle.readInteger(ByteOrder: .LittleEndian, Offset: nil, IsPeek: false))
        signature = try fileHandle.readUnsignedByteArray(ByteCountToRead: 0x100, Offset: nil, IsPeek: false)
        
        try fileHandle.seek(Offset: fileHandle.offset + 0x3C);
        let signerOffset = fileHandle.offset
        signer = try fileHandle.readString(Offset: nil, StringEncoding: String.Encoding.utf8, IsPeek: false)
        
        try fileHandle.seek(Offset: signerOffset + 0x40)
    }
}
