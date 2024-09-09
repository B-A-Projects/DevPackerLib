//
//  File.swift
//  
//
//  Created by Yannick de Boer on 08/08/2024.
//

import Foundation

public enum PartitionType: Codable {
    case System
    case Update
    case Game
    case Unknown(String)
    
    /// Returns the type of the partition,
    /// based on the identifier provided in `value`.
    ///
    /// This function will result in one of three results, depending
    /// on the provided input. Possible results are:
    /// - **`SI`**: Represents Japan
    /// - **`UP`**: Represents America
    /// - **`GM`**: Represents Europe & Oceania
    ///
    /// Any other value will result in
    /// `PartitionType.Unknown`
    ///
    /// - Parameters:
    ///     - Value: The value of which to determine the region.
    ///
    /// - Returns: The `PartitionType` value for `value`.
    static func Parse(Value value: String) -> PartitionType {
        guard value.count >= 2 else {
            return .Unknown(value)
        }
        
        switch value.prefix(0x2) {
        case "SI":
            return .System
        case "UP":
            return .Update
        case "GM":
            return .Game
        default:
            return .Unknown(value)
        }
    }
}
