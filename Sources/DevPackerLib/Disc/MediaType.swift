//
//  PackageType.swift
//  DevPackerUI
//
//  Created by Yannick de Boer on 20/01/2025.
//

import Foundation

/// Represents the type of disc.
///
/// The disc may be one of two types: **Disc**
/// and **Digital**.
///
/// Any value that does not conform to this
/// type selection is given the **unknown**
/// file type instead.
public enum MediaType: Codable {
    case Disc
    case Digital
    case Unknown(UInt8)
    
    /// Converts the value of the current
    /// `DiscType` instance to a numeric value.
    ///
    /// - Returns:The numeric value of the current
    /// `DiscType` instance as an unsigned 8-bit
    /// integer.
    public var Value: UInt8 {
        switch self {
        case .Disc:
            return 0x00
        case .Digital:
            return 0x01
        case .Unknown(let value):
            return value
        }
    }
    
    /// Returns the type of media the video game
    /// was sourced from, based on the identifier
    /// provided in `value`.
    ///
    /// This function will result in one of five results, depending
    /// on the provided input. Possible results are:
    /// - **`0x00`**: Represents a disc-based game
    /// - **`0x01`**: Represents a digital game
    ///
    /// Any other value will result in
    /// `MediaType.Unknown`
    ///
    /// - Parameters:
    ///     - Value: The value of which to determine the type.
    ///
    /// - Returns: The `MediaType` value for `value`.
    static func Parse(Value value: UInt8) -> MediaType {
        switch value {
        case 0x00:
            return .Disc
        case 0x01:
            return .Digital
        default:
            return .Unknown(value)
        }
    }
}
