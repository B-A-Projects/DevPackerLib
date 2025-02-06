//
//  Disc 2.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 24/01/2025.
//


import Foundation
import CryptoSwift

public struct Download: Game {
    
    public var name: String { get { return _name } }
    
    public var consoleType: ConsoleType { get { return _consoleType } }
    
    public var mediaType: MediaType { get { return _mediaType } }
    
    public var partitions: [Partition] { get { return _partitions } }
    
    public var directoryUrl: URL { get { return _directoryUrl } }
    
    private var _name: String
    private var _directoryUrl: URL
    private var _consoleType: ConsoleType
    private var _mediaType: MediaType
    private var _partitions: [VirtualPartition] = []
    
    private var _titleKey: [UInt8]
    private var _commonKey: [UInt8]
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: GameKeys.self)
        _name = try container.decode(String.self, forKey: .name)
        _directoryUrl = try container.decode(URL.self, forKey: .directoryUrl)
        _consoleType = try container.decode(ConsoleType.self, forKey: .consoleType)
        _mediaType = try container.decode(MediaType.self, forKey: .mediaType)
        _partitions = try container.decode([VirtualPartition].self, forKey: .partitions)
        _titleKey = try container.decode([UInt8].self, forKey: .titleKey)
        _commonKey = try container.decode([UInt8].self, forKey: .commonKey)
        
        for index in 0..._partitions.count - 1 {
            _partitions[index]._getDirectoryUrl = GetDirectoryUrl
        }
    }
    
    public init(Directory url: URL,
                TitleKey titleKey: [UInt8],
                CommonKey commonKey: [UInt8],
                ConsoleType type: ConsoleType
    ) throws {
        _directoryUrl = url
        _mediaType = .Disc
        _consoleType = type
        _titleKey = titleKey
        _commonKey = commonKey
        
        let ticketUrl = url.append(Component: "title.tik")
        let metadataUrl = url.append(Component: "title.tmd")
        let signatureUrl = url.append(Component: "title.cert")
        guard ticketUrl.fileExists() && metadataUrl.fileExists() && signatureUrl.fileExists() else {
            throw ReadError.FileNotFound
        }
        
        let signature = try Signature(File: try BinaryReader(Order: .BigEndian,
                                                             Path: signatureUrl))
        let ticket = try Ticket(File: try BinaryReader(Order: .BigEndian,
                                                       Path: ticketUrl),
                                DecryptionKey: _commonKey)
        let metadata = try Metadata(File: try BinaryReader(Order: .BigEndian,
                                                           Path: metadataUrl))
        
        _name = "\(ticket.primaryHeader.titleId.toHexString()) (digital)"
        _partitions.insert(try VirtualPartition(DirectoryUrl: url,
                                                Ticket: ticket,
                                                Metadata: metadata,
                                                CertificateChain: signature,
                                                GetDirectoryUrl: GetDirectoryUrl),
                           at: 0)
    }
    
    public func extract(DestinationUrl url: URL,
                        PartitionIndex partitionIndex: UInt32,
                        FilesystemTableIndex filesystemTableIndex: UInt32
     ) throws {
        guard partitionIndex < _partitions.count else {
            throw ReadError.InvalidValue
        }
        try _partitions[Int(partitionIndex)].extract(DestinationUrl: url,
                                                     FilesystemTableIndex: filesystemTableIndex)
     }
    
    private func GetDirectoryUrl() -> URL {
        return directoryUrl
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: GameKeys.self)
        try container.encode(_name, forKey: .name)
        try container.encode(_directoryUrl, forKey: .directoryUrl)
        try container.encode(_consoleType, forKey: .consoleType)
        try container.encode(_mediaType, forKey: .mediaType)
        try container.encode(_partitions, forKey: .partitions)
        try container.encode(_titleKey, forKey: .titleKey)
        try container.encode(_commonKey, forKey: .commonKey)
    }
}
