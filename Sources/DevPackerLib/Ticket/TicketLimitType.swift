//
//  File.swift
//  
//
//  Created by Yannick de Boer on 27/07/2024.
//

import Foundation

public enum TicketLimitType: Codable {
    case None(UInt32)
    case TimeLimit
    case BootCountLimit
    
    /// Converts the value of the current
    /// `TicketLimitType` instance to a
    /// numeric value.
    ///
    /// - Returns:The numeric value of the current
    /// `TicketLimitType` nstance as an
    /// unsigned 32-bit integer.
    var Value: UInt32 {
        switch self {
        case .TimeLimit:
            return 0x00000001
        case .BootCountLimit:
            return 0x00000004
        case .None(let value):
            return value
        }
    }
    
    /// Returns the type of limiter based on the
    /// identifier provided in `value`.
    ///
    /// This function will result in one of five results, depending
    /// on the provided input. Possible results are:
    /// - **`0x00000001`**: Represents a limit to how long the application can be used.
    /// - **`0x00000004`**: Represents a limit to how many times the application can be booted.
    ///
    /// Any other value will result in
    /// `TicketLimitType.Unknown`.
    ///
    /// - Parameters:
    ///     - Value: The value of which to determine the type.
    ///
    /// - Returns: The `TitleLimitType` value for `value`.
    static func Parse(Value value: UInt32) -> TicketLimitType {
        switch value {
        case 0x00000001:
            return .TimeLimit
        case 0x00000004:
            return .BootCountLimit
        default:
            return .None(value)
        }
    }
}
