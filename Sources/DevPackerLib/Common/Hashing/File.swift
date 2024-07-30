//
//  File.swift
//  
//
//  Created by Yannick de Boer on 26/07/2024.
//

import Foundation
import CryptoKit

@available(macOS 10.15.4, *)
public struct Hashing {
    
    public static func DigestSHA1(Input data: [UInt8]) -> [UInt8] {
        return Insecure.SHA1.hash(data: data).map({ $0 })
    }
}
