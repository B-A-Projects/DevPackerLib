//
//  WiiUGame.swift
//  DevPackerLib
//
//  Created by Yannick de Boer on 23/01/2025.
//

import Foundation
import CryptoSwift

protocol WiiUGame: Codable {
    
    var titleKey: String { get }
    
    var name: String { get }
    
    var consoleType: ConsoleType { get }
    
    var mediaType: MediaType { get }
    
    var partitions: [Partition] { get }
    
}
