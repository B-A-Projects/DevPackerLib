//
//  File.swift
//  
//
//  Created by Yannick de Boer on 15/07/2024.
//

import Foundation

public enum SignatureType: Codable {
    case Development
    case Retail
    case Unknown(UInt32)
    
    /// Converts the value of the current
    /// `SignatureType` instance to a
    /// numeric value.
    ///
    /// - Returns:The numeric value of the current
    /// `SignatureType` nstance as an
    /// unsigned 32-bit integer.
    var Value: UInt32 {
        switch self {
        case .Development:
            return 0x00010003
        case .Retail:
            return 0x00010004
        case .Unknown(let value):
            return value
        }
    }
    
    /// Returns the type of signature based on the
    /// identifier provided in `value`.
    ///
    /// This function will result in one of five results, depending
    /// on the provided input. Possible results are:
    /// - **`0x00010003`**: Represents a development signature.
    /// - **`0x00010004`**: Represents a retail signature.
    ///
    /// Any other value will result in
    /// `SignatureType.Unknown`.
    ///
    /// - Parameters:
    ///     - Value: The value of which to determine the type.
    ///
    /// - Returns: The `SignatureType` value for `value`.
    static func Parse(Value value: UInt32) -> SignatureType {
        switch value {
        case 0x00010003:
            return .Development
        case 0x00010004:
            return .Retail
        default:
            return .Unknown(value)
        }
    }
}
