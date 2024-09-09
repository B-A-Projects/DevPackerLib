//
//  MetadataContentChunkFlags.swift
//  
//
//  Created by Yannick de Boer on 17/07/2024.
//

import Foundation

/// Represents the type of an entry in the
/// filesystem table.
///
/// Content chunks may contain data for
/// one of four different content types:
/// **base games**, **updates**, **DLC**
/// and **shared content**.
///
/// Any value that does not conform to this
/// type selection is given the **unknown**
/// file type instead.
public enum MetadataContentChunkFlags: Codable {
    case BaseNoHash
    case BaseHash
    case UpdateNoHash
    case UpdateHash
    case AddonNoHash
    case AddonHash
    case SharedNoHash
    case SharedHash
    case Unknown(UInt16)
    
    /// Converts the value of the current
    /// `MetadataContentChunkFlags`
    /// instance to a numeric value.
    ///
    /// - Returns:The numeric value of the current
    /// `MetadataContentChunkFlags`
    /// instance as an unsigned 16-bit integer.
    var Value: UInt16 {
        switch self {
        case .BaseNoHash:
            return 0x0001
        case .BaseHash:
            return 0x0003
        case .UpdateNoHash:
            return 0x2001
        case .UpdateHash:
            return 0x2003
        case .AddonNoHash:
            return 0x4001
        case .AddonHash:
            return 0x4003
        case .SharedNoHash:
            return 0x8001
        case .SharedHash:
            return 0x8003
        case .Unknown(let value):
            return value
        }
    }
    
    /// Returns the type of file system entry based on the
    /// identifier provided in `value`.
    ///
    /// This function will result in one of five results, depending
    /// on the provided input. Possible results are:
    /// - **`0x0001`**: Represents a game chunk without hash tree
    /// - **`0x0003`**: Represents a game chunk with hash tree
    /// - **`0x2001`**: Represents an update chunk without hash tree
    /// - **`0x2003`**: Represents an update chunk with hash tree
    /// - **`0x4001`**: Represents a DLC chunk without hash tree
    /// - **`0x4003`**: Represents a DLC chunk with hash tree
    /// - **`0x8001`**: Represents a shared title chunk without hash tree
    /// - **`0x8003`**: Represents a shared title chunk with hash tree
    ///
    /// Any other value will result in
    /// `MetadataContentChunkFlags.Unknown`
    ///
    /// - Parameters:
    ///     - Value: The value of which to determine the type.
    ///
    /// - Returns: The `MetadataContentChunkFlags` value for `value`.
    static func Parse(Value value: UInt16) -> MetadataContentChunkFlags {
        switch value {
        case 0x0001:
            return .BaseNoHash
        case 0x0003:
            return .BaseHash
        case 0x2001:
            return .UpdateNoHash
        case 0x2003:
            return .UpdateHash
        case 0x4001:
            return .AddonNoHash
        case 0x4003:
            return .AddonHash
        case 0x8001:
            return .SharedNoHash
        case 0x8003:
            return .SharedHash
        default:
            return .Unknown(value)
        }
    }
}
