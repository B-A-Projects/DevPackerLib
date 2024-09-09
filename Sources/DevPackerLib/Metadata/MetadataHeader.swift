//
//  File.swift
//  
//
//  Created by Yannick de Boer on 12/07/2024.
//

import Foundation

/// Represents the main header of the title metadata file.
/// 
/// This object contains all properties related to the content
/// present in the title, and is covered by the **title metadata
/// signature**.
public struct MetadataHeader: Codable {
    
    /// The version number of the title metadata.
    var metadataVersion: UInt8
    
    /// The certificate revocation list version that is used by the certificate authority.
    var certificateAuthorityCrlVersion: UInt8
    
    /// The certificate revocation list version that is used by the signer.
    var signerCrlVersion: UInt8
    
    /// Determines whether this title is a virtual Wii or Wii U title.
    var isVirtualWiiTitle: Bool
    
    /// The minimum system version that is required for this software to be played.
    var systemVersion: UInt64
    
    /// The unique title ID for this software.
    var id: UInt64
    
    /// The type of title stored in this package. This may refer to a **game** or a **menu** application.
    var titleType: MetadataTitleType
    
    /// The group ID this title belongs to.
    var groupId: UInt16
    
    /// The region this title is assigned to.
    var region: MetadataRegion
    
    /// The ratings assigned to this title by the rating boards of different regions
    var ratings: [UInt8]
    
    /// The IPC mask of this title.
    var ipcMask: [uint8]
    
    /// Access right flags identifying system hardware this title requires to operate.
    var accessRights: UInt32
    
    /// The version number of this title.
    var titleVersion: UInt16
    
    /// The amount of content chunks contained within this metadata file.
    var contentChunkCount: UInt16
    
    /// The boot index referring to the entrypoint for this title.
    var bootIndex: UInt16
    
    var contentEntryTableHash: [UInt8]
    
    init (File fileHandle: Reader) throws {
        metadataVersion = try fileHandle.readInteger()
        certificateAuthorityCrlVersion = try fileHandle.readInteger()
        signerCrlVersion = try fileHandle.readInteger()
        isVirtualWiiTitle = try fileHandle.readBool()
        systemVersion = try fileHandle.readInteger()
        id = try fileHandle.readInteger()
        titleType = MetadataTitleType.Parse(Value: try fileHandle.readInteger())
        groupId = try fileHandle.readInteger()
        region = MetadataRegion.Parse(Value: try fileHandle.readInteger(Offset: fileHandle.offset + 0x2))
        ratings = try fileHandle.readUnsignedByteArray(ByteCountToRead: 0x10)
        ipcMask = try fileHandle.readUnsignedByteArray(ByteCountToRead: 0xC, 
                                                       Offset: fileHandle.offset + 0xC)
        accessRights = try fileHandle.readInteger(Offset: fileHandle.offset + 0x12)
        titleVersion = try fileHandle.readInteger()
        contentChunkCount = try fileHandle.readInteger()
        bootIndex = try fileHandle.readInteger()
        contentEntryTableHash = try fileHandle.readUnsignedByteArray(ByteCountToRead: 0x20, 
                                                                     Offset: fileHandle.offset + 0x2)
    }
}
