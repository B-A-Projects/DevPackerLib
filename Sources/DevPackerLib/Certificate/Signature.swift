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
    
    public init (File reader: Reader) throws {
        signatureType = SignatureType.Parse(Value: try reader.readInteger())
        signature = try reader.readUnsignedByteArray(ByteCountToRead: 0x100)
        
        try reader.seek(Offset: reader.offset + 0x3C);
        let signerOffset = reader.offset
        signer = try reader.readString()
        
        try reader.seek(Offset: signerOffset + 0x40)
    }
}
