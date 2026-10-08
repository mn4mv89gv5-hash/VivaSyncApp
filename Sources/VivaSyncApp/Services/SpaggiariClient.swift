import Foundation
import Security

public enum KeychainError: LocalizedError {
    case invalidInput
    case readFailed
    case writeFailed
    case deleteFailed

    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Credenziali non valide."
        case .readFailed:
            return "Impossibile leggere le credenziali salvate."
        case .writeFailed:
            return "Impossibile salvare le credenziali."
        case .deleteFailed:
            return "Impossibile eliminare le credenziali."
        }
    }
}

public final class KeychainManager {
    private static let usernameKey = "VivaSyncApp.username"
    private static let passwordKey = "VivaSyncApp.password"

    public static func save(username: String, password: String) throws {
        guard !username.isEmpty, !password.isEmpty else {
            throw KeychainError.invalidInput
        }

        try save(value: username, forKey: usernameKey)
        try save(value: password, forKey: passwordKey)
    }

    public static func read() throws -> (username: String, password: String)? {
        guard let username = try readValue(forKey: usernameKey),
              let password = try readValue(forKey: passwordKey) else {
            return nil
        }

        return (username, password)
    }

    public static func delete() throws {
        try deleteValue(forKey: usernameKey)
        try deleteValue(forKey: passwordKey)
    }

    private static func save(value: String, forKey key: String) throws {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.writeFailed
        }
    }

    private static func readValue(forKey key: String) throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.readFailed
        }

        guard let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.readFailed
        }

        return value
    }

    private static func deleteValue(forKey key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed
        }
    }
}
