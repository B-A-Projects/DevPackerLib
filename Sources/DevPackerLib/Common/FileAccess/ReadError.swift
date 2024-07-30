//
//  ReadError.swift
//  WudConverter
//
//  Created by Yannick de Boer on 15/02/2024.
//

import Foundation

enum ReadError: Error {
    case InvalidOffset(Offset: UInt64, Length: UInt64)
    case InvalidReadLength(Offset: UInt64, ReadLength: UInt64, FileLength: UInt64)
    case InvalidValueLength(ExpectedValueLength: UInt64, ActualValueLength: UInt64)
    case InvalidStringLength
    case Uninitialized
    case FileInitFailed
    case UnsupportedType(TypeName: String)
}
