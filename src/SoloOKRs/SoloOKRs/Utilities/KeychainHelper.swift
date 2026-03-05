// KeychainHelper.swift
// SoloOKRs
//
// Created by Claude on 2026-02-05.

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    
    private init() {}
    
    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecUseDataProtectionKeychain: true
        ] as [CFString: Any]
        
        // Add or update
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecUseDataProtectionKeychain: true
            ] as [CFString: Any]
            
            let attributesToUpdate = [kSecValueData: data] as [CFString: Any]
            
            SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        }
    }
    
    func read(service: String, account: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecUseDataProtectionKeychain: true
        ] as [CFString: Any]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        return result as? Data
    }
    
    func delete(service: String, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecUseDataProtectionKeychain: true
        ] as [CFString: Any]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // String helpers
    func save(_ string: String, service: String, account: String) {
        if let data = string.data(using: .utf8) {
            save(data, service: service, account: account)
        }
    }
    
    func readString(service: String, account: String) -> String? {
        if let data = read(service: service, account: account) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
