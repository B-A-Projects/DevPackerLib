//
//  MetadataTitleType.swift
//  
//
//  Created by Yannick de Boer on 15/07/2024.
//

import Foundation

/// Represents the type of an entry in the
/// filesystem table.
///
/// Titles are split up in two different types: 
/// **game** and **menu**.
///
/// **Games** are considered to be any
/// type of title that can be launched from a menu.
/// Any title that can be opened from the Wii 
/// U menu is considered to be a game.
///
/// **Menus** are titles that either act
/// as a menu, or system titles that can be
/// opened through the quick menu. 
/// Examples of such titles are the **Wii U menu**, **kiosk
/// menu** and **friend list app**.
///
/// Any value that does not conform to this
/// type selection is given the **unknown**
/// file type instead.
///
/// > Note: The title type is different from the 
/// > content type. Where the content
/// > type determines ***what type content
/// > that is part of a title is***, the title type
/// > determines ***whether the
/// > system should treat the title as an
/// > application or menu***.
public enum MetadataTitleType: Codable {
    case Game
    case Menu
    case Unknown(UInt32)
    
    /// Converts the value of the current
    /// `MetadataTitleType` instance to a
    /// numeric value.
    ///
    /// - Returns:The numeric value of the current
    /// `MetadataTitleType` nstance as an
    /// unsigned 32-bit integer.
    var Value: UInt32 {
        switch self {
        case .Game:
            return 0x00050000
        case .Menu:
            return 0x00050010
        case .Unknown(let value):
            return value
        }
    }
    
    /// Returns the type of file system entry based on the
    /// identifier provided in `value`.
    ///
    /// This function will result in one of five results, depending
    /// on the provided input. Possible results are:
    /// - **`0x00050000`**: Represents a game.
    /// - **`0x00050010`**: Represents a menu.
    ///
    /// Any other value will result in
    /// `MetadataTitleType.Unknown`.
    ///
    /// - Parameters:
    ///     - Value: The value of which to determine the type.
    ///
    /// - Returns: The `MetadataTitleType` value for `value`.
    static func Parse(Value value: UInt32) -> MetadataTitleType {
        switch value {
        case 0x00050000:
            return .Game
        case 0x00050010:
            return .Menu
        default:
            return .Unknown(value)
        }
    }
}
