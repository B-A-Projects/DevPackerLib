//
//  AESDecryptor.swift
//
//
//  Created by Marc Negoescu on 15.07.2024.
//

import Foundation
import CommonCrypto

class AESDecryptor {
    let key: Data // Initialized as a common Data type. BYO Wii U Dev Commom Key.
    let iv: Data // For Wii U Dev titles, the Initialization Vector is defined as a blank 16bit Hex Array.
    
    init(key: Data, iv: Data) {
        self.key = key
        self.iv = iv
    }
    
    func decrypt(data: Data) -> Data? {
            let keyLength = kCCKeySizeAES256
            let options = CCOptions(kCCOptionPKCS7Padding)
            var decryptedData = Data(count: data.count + kCCBlockSizeAES128)
            var localVariable = decryptedData
            
            var numBytesDecrypted: size_t = 0
            
            let cryptStatus = data.withUnsafeBytes { encryptedBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        localVariable.withUnsafeMutableBytes { decryptedBytes in
                            CCCrypt(
                                CCOperation(kCCDecrypt),
                                CCAlgorithm(kCCAlgorithmAES128),
                                options,
                                keyBytes.baseAddress,
                                keyLength,
                                ivBytes.baseAddress,
                                encryptedBytes.baseAddress,
                                data.count,
                                decryptedBytes.baseAddress,
                                decryptedData.count,
                                &numBytesDecrypted
                            )
                        }
                    }
                }
            }

            if cryptStatus == kCCSuccess {
                decryptedData.removeSubrange(numBytesDecrypted..<decryptedData.count)
                return decryptedData
            } else {
                print("Error: \(cryptStatus)")
                return nil
            }
        }
    }



