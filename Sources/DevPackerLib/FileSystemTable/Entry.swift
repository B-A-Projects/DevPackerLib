//
//  FileSystemTableEntry.swift
//  
//
//  Created by Yannick de Boer on 12/07/2024.
//

import Foundation

public struct FileSystemTableEntry: Codable {
    
    /// Represents the position of the entry inside of the filesystem table.
    public var index: UInt32
    
    /// Represents the type of the record.
    public var type: FileSystemTableEntryType
    
    /// Represents the offset to the name of this
    /// entry in the name table of the filesystem
    /// table.
    internal var nameOffset: UInt16
    
    /// The name of this entry, as stored in the
    /// name table of the filesystem table.
    public var name: String
    
    /// Represents the offset to the file data
    /// inside of the associated **`FileSystem
    /// TableGroupHeader`** entry. For folders,
    /// this value shows the depth of the folder
    /// inside of the file tree.
    ///
    /// > To get the proper file offset, this
    /// > value needs to be multiplied by the
    /// > **`fileOffsetFactor`** property from
    /// > the main filesystem table header.
    internal var offset: UInt32
    
    /// Represents the size of the file in bytes.
    /// For folders, this value indicates the index
    /// of the first record outside of this folder.
    public var byteSize: UInt32
    
    /// Contains a number of flags related to the content, including whether the content is encrypted.
    internal var flags: UInt16
    
    /// Represents the index of the **`FileSystem
    /// TableGroupHeader`** this entry belongs 
    /// to.
    internal var groupHeaderIndex: UInt16
    
    /// An array containing subsequent entries 
    /// that are part of this folder. This field is
    /// unused if the **`type`** of this record is not
    /// **`Folder`**.
    public var subEntries: [FileSystemTableEntry]?
    
    private var _offset: UInt64 = 0
    private var _byteSize: UInt64 = 0
    
    public init(File reader: Reader,
                EntryListOffset entryListOffset: UInt64,
                NameTableOffset nameTableOffset: UInt64,
                DefaultName defaultName: String? = nil
    ) throws {
        index = UInt32((reader.offset - entryListOffset) / 0x10)
        type = FileSystemTableEntryType.Parse(Value: try reader.readInteger())
        nameOffset = try reader.readInteger(Offset: reader.offset + 0x1)
        _offset = UInt64(try reader.readInteger() as UInt32)
        _byteSize = UInt64(try reader.readInteger() as UInt32)
        flags = try reader.readInteger()
        groupHeaderIndex = try reader.readInteger()
        
        let nameTableEntry = try reader.readString(Offset: nameTableOffset + UInt64(nameOffset), IsPeek: true)
        name = nameTableEntry.count > 0 ? nameTableEntry : defaultName ?? "root"
        
        if type.Value == FileSystemTableEntryType.Folder.Value {
            subEntries = []
            while UInt32((reader.offset - entryListOffset) / 0x10) < byteSize {
                subEntries!.insert(try FileSystemTableEntry(File: reader,
                                                           EntryListOffset: entryListOffset,
                                                           NameTableOffset: nameTableOffset
                                                          ), at: subEntries!.count)
            }
        } else {
            subEntries = nil
        }
    }
    
    public func getEntry(Index index: UInt32) -> FileSystemTableEntry? {
        if index == self.index {
            return self
        }
        
        guard subEntries != nil else {
            return nil
        }
        
        for subEntry in subEntries! {
            if let entry = subEntry.getEntry(Index: index) {
                return entry
            }
        }
        return nil
    }
    
    /// Extracts a file or folder from the
    /// associated content chunks in the
    /// provided directory. **This function is used
    /// for extracting files and folders from
    /// CDN content.**
    ///
    /// - Parameters:
    ///     - BaseDirectory: The directory URL in which to extract the
    ///     content.
    ///     - ContentChunks: The list of **`MetadataContentChunk
    ///     Entry`** records from which to extract the
    ///     files.
    public func extract(DestinationUrl destination: URL,
                        getFile: (_ index: UInt32,
                                  _ offset: UInt64,
                                  _ length: UInt64)
                        throws -> [UInt8]
    ) throws {
        switch type {
        case .File:
            try extractFile(DestinationUrl: destination, getFile: getFile)
            break
        case .Folder:
            try extractFolder(DestinationUrl: destination, getFile: getFile)
            break
        case .DeletedFile:
            break
        case .DeletedFolder:
            break
        case .Unknown(let value):
            break
        }
    }
    
    private func extractFolder(DestinationUrl destination: URL,
                               getFile: (_ index: UInt32,
                                         _ offset: UInt64,
                                         _ length: UInt64)
                               throws -> [UInt8]
    ) throws {
        let folderDirectory = destination.append(Component: name)
        if !folderDirectory.directoryExists() {
            try FileManager.default.createDirectory(at: folderDirectory,
                                                    withIntermediateDirectories: false)
        }
        
        try subEntries?.forEach {
            try $0.extract(DestinationUrl: folderDirectory, getFile: getFile)
        }
    }
    
    private func extractFile(DestinationUrl destination: URL,
                             getFile: (_ index: UInt32,
                                       _ offset: UInt64,
                                       _ length: UInt64)
                             throws -> [UInt8]
    ) throws {
        let fileData: [UInt8] = try getFile(index, _offset, _byteSize)
        
        let fileDirectory = destination.append(Component: name)
        if fileDirectory.fileExists() {
            try FileManager.default.removeItem(at: fileDirectory)
        }
        
        FileManager.default.createFile(atPath: fileDirectory.path(), contents: nil)
        //TODO: Add writer code here
    }
}
