//
//  Partition.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 24/01/2025.
//

import Foundation
import CryptoSwift

public struct VirtualPartition: Partition {
    
    public var partitionName: String { get { return _partitionName } }
    
    public var partitionType: PartitionType { get { return _partitionType } }
    
    public var filesystemTable: FilesystemTable { get { return _filesystemTable! } }
    
    /// This property acts as a function pointer to the `GetDirectoryUrl` function of the `Game` object, which is called upon during file extraction.
    internal var _getDirectoryUrl: () -> URL
    
    /// The total size of the filesystem table in bytes
    private var _filesystemTableSize: UInt64 = 0
    
    /// The total amount of H3 hashes present in the partition.
    private var _hashCount: UInt32 = 0
    
    /// The Wii U title ticket file
    private var _ticket: Ticket
    
    /// The Wii U title metadata file
    private var _metadata: Metadata
    
    /// The Wii U certificate chain file
    private var _certificateChain: Signature
    
    private var _partitionName: String
    private var _partitionType: PartitionType
    private var _filesystemTable: FilesystemTable? = nil
    
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: PartitionKeys.self)
        _partitionName = try values.decodeIfPresent(String.self, forKey: .partitionName)!
        _partitionType = try values.decodeIfPresent(PartitionType.self, forKey: .partitionType)!
        
        _filesystemTableSize = try values.decodeIfPresent(UInt64.self, forKey: .filesystemTableSize) ?? 0
        _filesystemTable = try values.decodeIfPresent(FilesystemTable.self, forKey: .filesystemTable)!
        
        _hashCount = try values.decodeIfPresent(UInt32.self, forKey: .hashCount) ?? 0
        
        _ticket = try values.decodeIfPresent(Ticket.self, forKey: .ticket)!
        _metadata = try values.decodeIfPresent(Metadata.self, forKey: .metadata)!
        _certificateChain = try values.decodeIfPresent(Signature.self, forKey: .signature)!
        
        _getDirectoryUrl = { URL(fileURLWithPath: "/") }
        
        _filesystemTable!._getGroup = getGroup(Group:FileOffset:FileSize:)
    }
    
    public init(DirectoryUrl url: URL,
                Ticket ticket: Ticket,
                Metadata metadata: Metadata,
                CertificateChain certificateChain: Signature,
                GetDirectoryUrl: @escaping () -> URL
    ) throws {
        _ticket = ticket
        _metadata = metadata
        _certificateChain = certificateChain
        _getDirectoryUrl = GetDirectoryUrl
        _partitionName = "GM\(_ticket.primaryHeader.titleId.toHexString())000000000000"
        _partitionType = .Game
        
        let filesystemUrl = url.append(Component: "\(metadata.contentChunks[0].chunkFileName).app")
        guard filesystemUrl.fileExists() else {
            throw ReadError.FileNotFound
        }
        let fileReader = try BinaryReader(Order: .BigEndian, Path: filesystemUrl)
        _filesystemTableSize = fileReader.length
        _filesystemTable = try FilesystemTable(File: fileReader,
                                               FilesystemTableOffset: 0,
                                               FilesystemTableSize: _filesystemTableSize,
                                               PartitionName: _partitionName,
                                               GetGroup: getGroup(Group:FileOffset:FileSize:),
                                               DecryptionKey: _ticket.primaryHeader.decryptedTitleKey)
    }
    
    public func extract(DestinationUrl destination: URL?,
                        FilesystemTableIndex filesystemTableIndex: UInt32
    ) throws -> [UInt8]? {
        return try _filesystemTable!.Extract(FilesystemTableIndex: filesystemTableIndex,
                                             DestinationUrl: destination)
    }
    
    /// Reads a specified range of bytes at the
    /// offset in the `FileSystemTableGroupHeader`
    /// entry provided.
    ///
    /// This function reads a specified range of
    /// bytes at an offset relative to the starting
    /// position of the `FileSystemTableGroupHeader`
    /// in this partition.
    ///
    /// If the `_key` property is set, decryption is
    /// performed on the partition level.
    ///
    /// - Parameters:
    ///     - Group: The `FileSystemTableGroupHeader` entry in which the file to be extracted is located.
    ///     - FileOffset: 0-based offset at which the file is located within the partition.
    ///     - FileSize: The total size of the file to be extracted, in bytes. For files in groups using hash trees, this number should be the total size of sectors in bytes.
    ///
    /// - Returns: An `UInt8` array containing the specified
    /// range of bytes from the specified
    /// `FileSystemTableGroupHeader` entry.
    private func getGroup(Group groupEntry: FileSystemTableGroupHeader,
                          FileOffset fileOffset: UInt64,
                          FileSize fileSize: UInt64
    ) throws -> [UInt8] {
        let directoryUrl = _getDirectoryUrl()
        
        let groupName = _metadata.contentChunks[Int(groupEntry.index)].chunkFileName
        let wudUrl = directoryUrl.append(Component: "\(groupName).app")
        guard wudUrl.fileExists() else {
            throw ReadError.FileNotFound
        }
        
        // let encryptionOffset: UInt64 = (_key != nil && fileOffset > 0 ? 0x10 : 0)
        let absoluteOffset = groupEntry.groupOffset + fileOffset //- encryptionOffset
        let partitionReader = try BinaryReader(Order: .BigEndian,
                                               Path: wudUrl)
        let chunkBytes = try partitionReader.readUnsignedByteArray(ByteCountToRead: fileSize,
                                                                   Offset: absoluteOffset)
        
//        if _key != nil {
//            let aes = try AES(key: _key!,
//                              blockMode: CBC(iv: Array(repeating: 0, count: 0x10)),
//                              padding: .noPadding)
//            return try aes.decrypt(Array(chunkBytes[Int(encryptionOffset)...]))
//        }
        return chunkBytes
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: PartitionKeys.self)
        try container.encode(_partitionName, forKey: .partitionName)
        try container.encode(_partitionType, forKey: .partitionType)
        
        try container.encode(_filesystemTableSize, forKey: .filesystemTableSize)
        try container.encode(_filesystemTable, forKey: .filesystemTable)
        
        try container.encode(_hashCount, forKey: .hashCount)
        
        try container.encode(_ticket, forKey: .ticket)
        try container.encode(_metadata, forKey: .metadata)
        try container.encode(_certificateChain, forKey: .signature)
    }
}
