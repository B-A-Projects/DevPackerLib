//
//  FileSystemTableEntry.swift
//  
//
//  Created by Yannick de Boer on 12/07/2024.
//

import Foundation

public struct FileSystemTableEntry: Codable {
    
    /// Represents the position of the entry
    /// inside of the filesystem table.
    public var index: UInt32 { get { return _index } }
    
    /// The name of this entry, as stored in the
    /// name table of the filesystem table.
    public var name: String { get { return _name } }
    
    /// Represents the type of the record.
    public var type: FileSystemTableEntryType { get { return _type } }
    
    /// Represents the size of the file in bytes.
    /// For folders, this value indicates the index
    /// of the first record outside of this folder.
    public var byteSize: UInt64 { get { return _byteSize } }
    
    /// Represents the index of the **`FileSystem
    /// TableGroupHeader`** this entry belongs 
    /// to.
    public var groupHeaderIndex: UInt16 { get { return _groupHeaderIndex } }
    
    /// Contains a number of flags related to the
    /// content, including whether the content is
    /// encrypted.
    public var flags: UInt16 { get { return _flags } }
    
    /// An array containing subsequent entries 
    /// that are part of this folder. This field is
    /// unused if the **`type`** of this record is not
    /// **`Folder`**.
    public var subEntries: [FileSystemTableEntry]? { get { return _subEntries } }
    
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
    private var _offset: UInt64 = 0
    
    /// Represents the offset to the name of this
    /// entry in the name table of the filesystem
    /// table.
    private var _nameOffset: UInt64 = 0
    
    private var _index: UInt32 = 0
    private var _name: String
    private var _type: FileSystemTableEntryType
    private var _byteSize: UInt64 = 0
    private var _groupHeaderIndex: UInt16 = 0
    private var _flags: UInt16
    private var _subEntries: [FileSystemTableEntry]?
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: FilesystemEntryKeys.self)
        self._offset = try container.decode(UInt64.self, forKey: .offset)
        self._nameOffset = try container.decode(UInt64.self, forKey: .nameOffset)
        self._byteSize = try container.decode(UInt64.self, forKey: .byteSize)
        self._index = try container.decode(UInt32.self, forKey: .index)
        self._name = try container.decode(String.self, forKey: .name)
        self._groupHeaderIndex = try container.decode(UInt16.self, forKey: .groupHeaderIndex)
        self._type = try container.decode(FileSystemTableEntryType.self, forKey: .type)
        self._flags = try container.decode(UInt16.self, forKey: .flags)
        self._subEntries = try container.decodeIfPresent([FileSystemTableEntry].self, forKey: .subEntries)
    }
    
    public init(File reader: Reader,
                EntryListOffset entryListOffset: UInt64,
                NameTableOffset nameTableOffset: UInt64,
                DefaultName defaultName: String? = nil
    ) throws {
        _index = UInt32((reader.offset - entryListOffset) / 0x10)
        _type = FileSystemTableEntryType.Parse(Value: try reader.readInteger())
        _nameOffset = try reader.readInteger(Offset: reader.offset + 0x1)
        _offset = UInt64(try reader.readInteger() as UInt32)
        _byteSize = UInt64(try reader.readInteger() as UInt32)
        _flags = try reader.readInteger()
        _groupHeaderIndex = try reader.readInteger()
        
        let nameTableEntry = try reader.readString(Offset: nameTableOffset + UInt64(_nameOffset), IsPeek: true)
        _name = nameTableEntry.count > 0 ? nameTableEntry : defaultName ?? "root"
        
        if type.Value == FileSystemTableEntryType.Folder.Value {
            _subEntries = []
            while UInt32((reader.offset - entryListOffset) / 0x10) < _byteSize {
                _subEntries!.insert(try FileSystemTableEntry(File: reader,
                                                             EntryListOffset: entryListOffset,
                                                             NameTableOffset: nameTableOffset),
                                    at: subEntries!.count)
            }
        } else {
            _subEntries = nil
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
    
    public func getEntry(Name name: String) -> FileSystemTableEntry? {
        if name == self.name {
            return self
        }
        
        guard subEntries != nil else {
            return nil
        }
        
        for subEntry in subEntries! {
            if let entry = subEntry.getEntry(Name: name) {
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
    public func extract(DestinationUrl destination: URL?,
                        getFile: (_ index: UInt32,
                                  _ offset: UInt64,
                                  _ length: UInt64)
                        throws -> [UInt8]
    ) throws -> [UInt8]? {
        switch type {
        case .File:
            return try extractFile(DestinationUrl: destination, getFile: getFile)
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
        return nil
    }
    
    private func extractFolder(DestinationUrl destination: URL?,
                               getFile: (_ index: UInt32,
                                         _ offset: UInt64,
                                         _ length: UInt64)
                               throws -> [UInt8]
    ) throws {
        guard destination != nil else {
            return
        }
        
        let folderDirectory = destination!.append(Component: name)
        if !folderDirectory.directoryExists() {
            try FileManager.default.createDirectory(at: folderDirectory,
                                                    withIntermediateDirectories: false)
        }
        
        try subEntries?.forEach {
            try $0.extract(DestinationUrl: folderDirectory, getFile: getFile)
        }
    }
    
    private func extractFile(DestinationUrl destination: URL?,
                             getFile: (_ index: UInt32,
                                       _ offset: UInt64,
                                       _ length: UInt64)
                             throws -> [UInt8]
    ) throws -> [UInt8]? {
        let fileData: [UInt8] = try getFile(index, _offset, _byteSize)
        if destination == nil {
            return fileData
        }
        
        let fileDirectory = destination!.append(Component: name)
        if fileDirectory.fileExists() {
            try FileManager.default.removeItem(at: fileDirectory)
        }
        
        FileManager.default.createFile(atPath: fileDirectory.path(), contents: nil)
        //TODO: Add writer code here
        return nil
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: FilesystemEntryKeys.self)
        try container.encode(_index, forKey: .index)
        try container.encode(_name, forKey: .name)
        try container.encode(_nameOffset, forKey: .nameOffset)
        try container.encode(_type, forKey: .type)
        try container.encode(_offset, forKey: .offset)
        try container.encode(_byteSize, forKey: .byteSize)
        try container.encode(_groupHeaderIndex, forKey: .groupHeaderIndex)
        try container.encode(_flags, forKey: .flags)
        try container.encode(_subEntries, forKey: .subEntries)
    }
}
