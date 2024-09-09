//
//  FileSystemTableEntryType.swift
//
//
//  Created by Yannick de Boer on 12/07/2024.
//

import Foundation

/// Represents the type of an entry in the 
/// filesystem table.
///
/// The filesystem table may contain four
/// different types of records: **files**,
/// **folders**, **deleted files** and
/// **deleted folders**.
///
/// Any value that does not conform to this
/// type selection is given the **unknown**
/// file type instead.
public enum FileSystemTableEntryType: Codable {
    case Folder
    case File
    case DeletedFolder
    case DeletedFile
    case Unknown(UInt8)
    
    /// Converts the value of the current
    /// `FileSystemTableEntryType`
    /// instance to a numeric value.
    ///
    /// - Returns:The numeric value of the current
    /// `FileSystemTableEntryType`
    /// instance as an unsigned 8-bit integer.
    public var Value: UInt8 {
        switch self {
        case .File:
            return 0x00
        case .Folder:
            return 0x01
        case .DeletedFile:
            return 0x80
        case .DeletedFolder:
            return 0x81
        case .Unknown(let value):
            return value
        }
    }
    
    /// Returns the type of file system entry based on the
    /// identifier provided in `value`.
    ///
    /// This function will result in one of five results, depending
    /// on the provided input. Possible results are:
    /// - **`0x00`**: Represents a folder
    /// - **`0x01`**: Represents a file
    /// - **`0x80`**: Represents a deleted folder
    /// - **`0x81`**: Represents a deleted file
    ///
    /// Any other value will result in
    /// `FileSystemTableEntryType.Unknown`
    ///
    /// - Parameters:
    ///     - Value: The value of which to determine the type.
    ///
    /// - Returns: The `FileSystemTableEntryType` value for `value`.
    static func Parse(Value value: UInt8) -> FileSystemTableEntryType {
        switch value {
        case 0x00:
            return .File
        case 0x01:
            return .Folder
        case 0x80:
            return .DeletedFile
        case 0x81:
            return .DeletedFolder
        default:
            return .Unknown(value)
        }
    }
}
