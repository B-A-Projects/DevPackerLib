//
//  Partition.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 24/01/2025.
//

import Foundation
import CryptoSwift

struct VirtualPartition: Partition {
    
    public var partitionName: String { get { return _partitionName } }
    
    public var partitionType: PartitionType { get { return _partitionType } }
    
    public var filesystemTable: FilesystemTable { get { return _filesystemTable } }
    
    private var _partitionName: String
    private var _partitionType: PartitionType
    private var _filesystemTable: FilesystemTable
    private var _key: [UInt8]? = nil
    
    private var _partitionOffset: UInt64 = 0
    private var _filesystemTableOffset: UInt64 = 0
    private var _partitionSize: UInt64 = 0
    private var _filesystemTableSize = 0
    private var _hashBlockSize = 0
    private var _hashCount = 0
    
    private var _ticket: Ticket? = nil
    private var _metadata: Metadata? = nil
    private var _certificateChain: Signature? = nil
    
    public init(from decoder: any Decoder) throws {
        
    }
    
    public init(PartitionType type: PartitionType,
                DirectoryUrl url: URL,
                DecryptionKey key: [UInt8]? = nil,
                Ticket ticket: Ticket? = nil,
                Metadata metadata: Metadata? = nil,
                CertificateChain certificateChain: Signature? = nil
    ) throws {
        _partitionType = type
        _ticket = ticket
        _metadata = metadata
        _certificateChain = certificateChain
        
        switch type {
        case .System:
            _partitionName = type.Value
            _filesystemTable = try VirtualFilesystemTable()
        case .Game:
            guard key != nil && _ticket != nil && _metadata != nil else {
                throw ReadError.Uninitialized
            }
            _partitionName = "GM\(_ticket!.primaryHeader.titleId.toHexString())000000000000"
            _key = try _ticket!.getDecryptionKey(DecryptionKey: key!)
            
            let filesystemUrl = url.append(Component: "\(metadata!.contentChunks[0].chunkFileName).app")
            guard filesystemUrl.fileExists() else {
                throw ReadError.FileNotFound
            }
            let fileReader = try BinaryReader(Order: .BigEndian, Path: filesystemUrl)
            let encryptedFilesystemTable = try fileReader.readUnsignedByteArray(ByteCountToRead: fileReader.length)
            
            let aes = try AES(key: _key!,
                              blockMode: CBC(iv: Array(repeating: 0, count: 0x10)),
                              padding: .noPadding)
            var memoryReader = try MemoryReader(From: aes.decrypt(encryptedFilesystemTable),
                                                ByteOrder: .BigEndian)
            _filesystemTable = try DiscFilesystemTable(PartitionName: _partitionName,
                                                       File: memoryReader,
                                                       DirectoryPath: url)
        default:
            throw ReadError.InvalidValue
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        
    }
}
