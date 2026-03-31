//
//  KeychainService.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-31.
//

import Foundation
import LocalAuthentication
import Security

struct KeychainService {
    private static let service = "BudgetingApp.Auth"
    private static let accountsKey = "savedAccountEmails"

    static func savedAccounts() -> [String] {
        UserDefaults.standard.stringArray(forKey: accountsKey) ?? []
    }

    static func saveCredentials(email: String, password: String) -> Bool {
        let account = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !account.isEmpty, !password.isEmpty else { return false }
        let data = Data(password.utf8)

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(baseQuery as CFDictionary)

        var accessControl: SecAccessControl?
        accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .biometryCurrentSet,
            nil
        )

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        if let accessControl = accessControl {
            attributes[kSecAttrAccessControl as String] = accessControl
        } else {
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status == errSecSuccess {
            addAccount(account)
            return true
        }
        return false
    }

    static func loadCredentials(email: String, reason: String, completion: @escaping (Result<String, Error>) -> Void) {
        let account = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !account.isEmpty else {
            completion(.failure(NSError(domain: "KeychainService", code: 400)))
            return
        }

        let context = LAContext()
        context.localizedReason = reason

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context,
            kSecUseOperationPrompt as String: reason
        ]

        DispatchQueue.global(qos: .userInitiated).async {
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            if status == errSecSuccess, let data = item as? Data, let password = String(data: data, encoding: .utf8) {
                completion(.success(password))
            } else {
                completion(.failure(NSError(domain: "KeychainService", code: Int(status))))
            }
        }
    }

    static func removeCredentials(email: String) {
        let account = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !account.isEmpty else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        removeAccount(account)
    }

    private static func addAccount(_ email: String) {
        var list = savedAccounts()
        if !list.contains(email) {
            list.append(email)
            UserDefaults.standard.set(list, forKey: accountsKey)
        }
    }

    private static func removeAccount(_ email: String) {
        var list = savedAccounts()
        list.removeAll { $0 == email }
        UserDefaults.standard.set(list, forKey: accountsKey)
    }
}
