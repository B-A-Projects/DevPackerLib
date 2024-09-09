//
//  File.swift
//  
//
//  Created by Yannick de Boer on 01/08/2024.
//

import Foundation

extension URL {
    
    public func append(Component component: String) -> URL {
        if #available(macOS 13.0, *) {
            return self.appending(component: component)
        } else {
            return self.appendingPathComponent(component)
        }
    }
    
    public func path() -> String {
        if #available(macOS 13.0, *) {
            return self.path(percentEncoded: false)
        } else {
            return self.path
        }
    }
    
    public func fileExists() -> Bool {
        if #available(macOS 13.0, *) {
            if FileManager.default.fileExists(atPath: self.path(percentEncoded: false)) {
                return true
            }
        } else {
            if FileManager.default.fileExists(atPath: self.path) {
                return true
            }
        }
        return false
    }
    
    public func directoryExists() -> Bool {
        var isDirectory = ObjCBool(true)
        if #available(macOS 13.0, *) {
            if FileManager.default.fileExists(atPath: self.path(percentEncoded: false), isDirectory: &isDirectory) {
                return isDirectory.boolValue
            }
        } else {
            if FileManager.default.fileExists(atPath: self.path, isDirectory: &isDirectory) {
                return isDirectory.boolValue
            }
        }
        return true
    }
}
