//
//  MetadataRegion.swift
//  
//
//  Created by Yannick de Boer on 15/07/2024.
//

import Foundation

/// Represents the region for which the
/// title is intended.
///
/// The defined region may be one of four
/// different locales: **Japan**,
/// **America**, **Europe & Oceania**,
/// **Korea**. Region-free titles use the
/// **universal** region type instead.
///
/// Any value that does not conform to this
/// type selection is given the **unknown**
/// region instead.
public enum MetadataRegion: Codable {
    case Japan
    case America
    case Europe
    case Korea
    //case China
    //case Taiwan
    case Universal
    case Unknown(UInt16)
    
    /// Converts the value of the current
    /// `MetadataRegion` instance to
    /// a numeric value.
    ///
    /// - Returns:The numeric value of the current
    /// `MetadataRegion` instance as an
    /// unsigned 16-bit integer.
    var Value: UInt16 {
        switch self {
        case .Japan:
            return 0x0000
        case .America:
            return 0x0001
        case .Europe:
            return 0x0002
        case .Universal:
            return 0x0003
        case .Korea:
            return 0x0004
        case .Unknown(let value):
            return value
        }
    }
    
    /// Returns the region for which this title is packed,
    /// based on the identifier provided in `value`.
    ///
    /// This function will result in one of six results, depending
    /// on the provided input. Possible results are:
    /// - **`0x0000`**: Represents Japan
    /// - **`0x0001`**: Represents America
    /// - **`0x0002`**: Represents Europe & Oceania
    /// - **`0x0003`**: Represents a region-free title
    /// - **`0x0004`**: Represents Korea
    ///
    /// Any other value will result in
    /// `MetadataRegion.Unknown`
    ///
    /// - Parameters:
    ///     - Value: The value of which to determine the region.
    ///
    /// - Returns: The `MetadataRegion` value for `value`.
    ///
    /// > Warning: This value only reflects currently known regions.
    /// > There may be other regions (e.g. Taiwan, China) that
    /// > currently do not have an associated value.
    static func Parse(Value value: UInt16) -> MetadataRegion {
        switch value {
        case 0x0000:
            return .Japan
        case 0x0001:
            return .America
        case 0x0002:
            return .Europe
        case 0x0003:
            return .Universal
        case 0x0004:
            return .Korea
        default:
            return .Unknown(value)
        }
    }
}
