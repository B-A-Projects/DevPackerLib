//
//  Configkeys.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 03/02/2025.
//

enum GameKeys: String, CodingKey {
    case name = "default"
    case consoleType
    case mediaType
    case partitions
    case directoryUrl
    case titleKey
    case commonKey
}

enum PartitionKeys: String, CodingKey {
    case partitionName = "default"
    case partitionIndex
    case partitionType
    case partitionOffset
    case partitionSize
    case filesystemTable
    case filesystemTableOffset
    case filesystemTableSize
    case hashBlockSize
    case hashCount
    case ticket
    case metadata
    case signature
    case key
}

enum FilesystemKeys: String, CodingKey {
    case fileOffsetFactor = "32"
    case groupHeaders
    case entryTable
    case partitionType
    case key
}

enum FilesystemGroupKeys: String, CodingKey {
    case index = "0"
    case groupOffset
    case groupSize
    case ownerTitleId
    case groupId
    case flags
}

enum FilesystemEntryKeys: String, CodingKey {
    case name = "default"
    case type
    case offset
    case nameOffset
    case byteSize
    case index
    case groupHeaderIndex
    case flags
    case subEntries
}
