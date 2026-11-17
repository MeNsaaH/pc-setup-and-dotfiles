//
// secrets: a TTL cache for CLI secrets, sealed by the Secure Enclave.
//
// Build and sign it once per Mac:
//   swiftc -O -o ~/.local/bin/secrets ~/.config/secrets/secrets.swift
//   codesign --force --sign - ~/.local/bin/secrets
//
//   secrets read <ref> [--ttl SECONDS] [--refresh]
//   secrets list
//   secrets clear [<ref>]
//   secrets status
//
// The source comes from the reference scheme:
//   op://vault/item/field           op read
//   lpass://Group/Item[?field=f]    lpass show --password, or --field=f
//   keychain://service[/account]    security find-generic-password -w
//   cmd://<shell command>           /bin/sh -c
// A bare name is appended to $SECRETS_DEFAULT_REF, so `secrets read GITLAB_TOKEN`
// resolves the same way the direnv helper does.
//
// The plaintext is fetched at most once per TTL (default 300s), sealed for a
// Secure Enclave P-256 key (ephemeral ECDH + HKDF-SHA256 + AES-256-GCM), and
// the ciphertext is stored in the login keychain. A process that can read the
// keychain or $HOME finds ciphertext it cannot open: the private key never
// leaves the hardware.

import Foundation
import CryptoKit
import Security

// MARK: - Configuration

let defaultTTL = 300
let keychainAccount = "secrets"
let hkdfInfo = "secrets-v1".data(using: .utf8)!

let stateDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".local/state/secrets")
let keyFilePath = stateDir.appendingPathComponent("key.dat")

// MARK: - Errors and output

struct Failure: Error, CustomStringConvertible {
    let description: String
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write("secrets: \(message)\n".data(using: .utf8)!)
    exit(1)
}

func warn(_ message: String) {
    FileHandle.standardError.write("secrets: \(message)\n".data(using: .utf8)!)
}

// MARK: - Cache metadata

/// Stored as JSON in the keychain item comment, next to the ciphertext.
struct CacheMetadata: Codable {
    var timestamp: Int
    var ttl: Int

    init(timestamp: Int = Int(Date().timeIntervalSince1970), ttl: Int) {
        self.timestamp = timestamp
        self.ttl = ttl
    }

    var age: Int { Int(Date().timeIntervalSince1970) - timestamp }
    var remaining: Int { ttl - age }
    var isExpired: Bool { remaining <= 0 }
}

// MARK: - Secure Enclave key and ECIES

enum Enclave {

    static func loadOrCreateKey() throws -> SecureEnclave.P256.KeyAgreement.PrivateKey {
        if FileManager.default.fileExists(atPath: keyFilePath.path) {
            let data = try Data(contentsOf: keyFilePath)
            return try SecureEnclave.P256.KeyAgreement.PrivateKey(dataRepresentation: data)
        }
        guard SecureEnclave.isAvailable else {
            throw Failure(description: "no Secure Enclave on this Mac")
        }
        let key = try SecureEnclave.P256.KeyAgreement.PrivateKey()
        try FileManager.default.createDirectory(
            at: stateDir, withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700])
        try key.dataRepresentation.write(to: keyFilePath, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600], ofItemAtPath: keyFilePath.path)
        return key
    }

    /// Blob layout: [2-byte big-endian ephemeral key length][ephemeral key][AES-GCM combined].
    static func seal(_ plaintext: Data, to publicKey: P256.KeyAgreement.PublicKey) throws -> Data {
        let ephemeral = P256.KeyAgreement.PrivateKey()
        let shared = try ephemeral.sharedSecretFromKeyAgreement(with: publicKey)
        let key = shared.hkdfDerivedSymmetricKey(
            using: SHA256.self, salt: Data(), sharedInfo: hkdfInfo, outputByteCount: 32)
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else {
            throw Failure(description: "sealed box has no combined representation")
        }
        let ephemeralKey = ephemeral.publicKey.rawRepresentation
        var blob = Data()
        blob.append(UInt8(ephemeralKey.count >> 8))
        blob.append(UInt8(ephemeralKey.count & 0xff))
        blob.append(ephemeralKey)
        blob.append(combined)
        return blob
    }

    static func open(_ blob: Data, with privateKey: SecureEnclave.P256.KeyAgreement.PrivateKey) throws -> Data {
        let bytes = [UInt8](blob)
        guard bytes.count >= 2 else { throw Failure(description: "cached ciphertext is truncated") }
        let keyLength = Int(bytes[0]) << 8 | Int(bytes[1])
        // nonce (12) + at least one byte of ciphertext + tag (16)
        guard bytes.count >= 2 + keyLength + 12 + 1 + 16 else {
            throw Failure(description: "cached ciphertext is truncated")
        }
        let ephemeralPublicKey = try P256.KeyAgreement.PublicKey(
            rawRepresentation: Data(bytes[2 ..< 2 + keyLength]))
        let combined = Data(bytes[(2 + keyLength)...])
        let shared = try privateKey.sharedSecretFromKeyAgreement(with: ephemeralPublicKey)
        let key = shared.hkdfDerivedSymmetricKey(
            using: SHA256.self, salt: Data(), sharedInfo: hkdfInfo, outputByteCount: 32)
        return try AES.GCM.open(try AES.GCM.SealedBox(combined: combined), using: key)
    }
}

// MARK: - Keychain

enum Keychain {

    private static func baseQuery(_ ref: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: ref,
            kSecAttrAccount as String: keychainAccount,
        ]
    }

    static func save(_ ref: String, ciphertext: Data, metadata: CacheMetadata) throws {
        let comment = String(data: try JSONEncoder().encode(metadata), encoding: .utf8)!
        let update: [String: Any] = [
            kSecValueData as String: ciphertext,
            kSecAttrComment as String: comment,
        ]
        var query = baseQuery(ref)
        if SecItemUpdate(query as CFDictionary, update as CFDictionary) == errSecSuccess {
            return
        }
        query.merge(update) { current, _ in current }
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw Failure(description: "keychain write failed for \(ref) (OSStatus \(status))")
        }
    }

    static func load(_ ref: String) throws -> (ciphertext: Data, metadata: CacheMetadata)? {
        var query = baseQuery(ref)
        query[kSecReturnData as String] = true
        query[kSecReturnAttributes as String] = true
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let attributes = item as? [String: Any],
              let ciphertext = attributes[kSecValueData as String] as? Data,
              let comment = attributes[kSecAttrComment as String] as? String,
              let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: Data(comment.utf8))
        else {
            throw Failure(description: "keychain entry for \(ref) is unreadable (OSStatus \(status))")
        }
        return (ciphertext, metadata)
    }

    static func touch(_ ref: String, ttl: Int) throws {
        let comment = String(data: try JSONEncoder().encode(CacheMetadata(ttl: ttl)), encoding: .utf8)!
        let status = SecItemUpdate(
            baseQuery(ref) as CFDictionary,
            [kSecAttrComment as String: comment] as CFDictionary)
        guard status == errSecSuccess else {
            throw Failure(description: "keychain update failed for \(ref) (OSStatus \(status))")
        }
    }

    static func delete(_ ref: String) throws {
        let status = SecItemDelete(baseQuery(ref) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw Failure(description: "keychain delete failed for \(ref) (OSStatus \(status))")
        }
    }

    static func list() throws -> [(ref: String, metadata: CacheMetadata)] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
            // The file-based login keychain, so listing never raises a UI prompt.
            kSecUseDataProtectionKeychain as String: false,
        ]
        var items: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &items)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let results = items as? [[String: Any]] else {
            throw Failure(description: "keychain list failed (OSStatus \(status))")
        }
        return results.compactMap { attributes in
            guard let ref = attributes[kSecAttrService as String] as? String,
                  let comment = attributes[kSecAttrComment as String] as? String,
                  let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: Data(comment.utf8))
            else { return nil }
            return (ref, metadata)
        }
    }

    static func deleteAll() throws -> Int {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
        ]
        let matches = try list()
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw Failure(description: "keychain delete failed (OSStatus \(status))")
        }
        return matches.count
    }
}

// MARK: - Sources

enum Source {
    case op(String)
    case lpass(item: String, field: String?)
    case keychain(service: String, account: String?)
    case cmd(String)
}

func resolveReference(_ raw: String) -> String {
    if raw.contains("://") { return raw }
    let prefix = ProcessInfo.processInfo.environment["SECRETS_DEFAULT_REF"] ?? ""
    guard !prefix.isEmpty else {
        fail("'\(raw)' has no scheme and SECRETS_DEFAULT_REF is unset")
    }
    return prefix.hasSuffix("/") ? prefix + raw : prefix + "/" + raw
}

func parseSource(_ reference: String) -> Source {
    guard let separator = reference.range(of: "://") else {
        fail("'\(reference)' is not a reference (expected scheme://path)")
    }
    let scheme = String(reference[reference.startIndex ..< separator.lowerBound])
    let rest = String(reference[separator.upperBound...])

    switch scheme {
    case "op":
        guard !rest.isEmpty else { fail("op reference needs a path: op://vault/item/field") }
        return .op(rest)
    case "lpass":
        var item = rest
        var field: String?
        if let queryStart = rest.firstIndex(of: "?") {
            item = String(rest[rest.startIndex ..< queryStart])
            for pair in rest[rest.index(after: queryStart)...].split(separator: "&") {
                let parts = pair.split(separator: "=", maxSplits: 1)
                if parts.count == 2, parts[0] == "field" {
                    field = String(parts[1])
                }
            }
        }
        guard !item.isEmpty else { fail("lpass reference needs an item: lpass://Group/Item") }
        return .lpass(item: item, field: field)
    case "keychain":
        guard !rest.isEmpty else { fail("keychain reference needs a service: keychain://service/account") }
        if let slash = rest.firstIndex(of: "/") {
            return .keychain(
                service: String(rest[rest.startIndex ..< slash]),
                account: String(rest[rest.index(after: slash)...]))
        }
        return .keychain(service: rest, account: nil)
    case "cmd":
        guard !rest.isEmpty else { fail("cmd reference needs a command") }
        return .cmd(rest)
    default:
        fail("unknown reference scheme '\(scheme)'")
    }
}

/// Runs a command, returns trimmed stdout, and passes its stderr through so
/// 1Password prompts, Touch ID dialogs and lpass errors reach the terminal.
func run(_ executable: String, _ arguments: [String], what: String) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    let stdout = Pipe()
    process.standardOutput = stdout
    process.standardError = FileHandle.standardError
    do {
        try process.run()
    } catch {
        fail("cannot run \(what): \(error.localizedDescription)")
    }
    let data = stdout.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        fail("\(what) failed (exit \(process.terminationStatus))")
    }
    guard let value = String(data: data, encoding: .utf8) else {
        fail("\(what) returned bytes that are not UTF-8")
    }
    return value.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n"))
}

func fetch(_ reference: String) -> String {
    switch parseSource(reference) {
    case .op(let path):
        return run("/usr/bin/env", ["op", "read", "op://" + path], what: "op read")
    case .lpass(let item, let field):
        if let field {
            return run("/usr/bin/env", ["lpass", "show", "--field=\(field)", item], what: "lpass show")
        }
        return run("/usr/bin/env", ["lpass", "show", "--password", item], what: "lpass show")
    case .keychain(let service, let account):
        var arguments = ["find-generic-password", "-s", service]
        if let account { arguments += ["-a", account] }
        arguments.append("-w")
        return run("/usr/bin/security", arguments, what: "security find-generic-password")
    case .cmd(let command):
        return run("/bin/sh", ["-c", command], what: "cmd")
    }
}

// MARK: - Commands

func commandRead(_ arguments: [String]) throws {
    guard let raw = arguments.first, !raw.hasPrefix("-") else {
        fail("usage: secrets read <ref> [--ttl SECONDS] [--refresh]")
    }
    var ttl = Int(ProcessInfo.processInfo.environment["SECRETS_TTL"] ?? "") ?? defaultTTL
    var refresh = false
    var index = 1
    while index < arguments.count {
        switch arguments[index] {
        case "--ttl":
            index += 1
            guard index < arguments.count, let value = Int(arguments[index]), value > 0 else {
                fail("--ttl needs a positive number of seconds")
            }
            ttl = value
        case "--refresh":
            refresh = true
        default:
            fail("unknown option '\(arguments[index])'")
        }
        index += 1
    }

    let reference = resolveReference(raw)
    let cached = try? Keychain.load(reference)

    if !refresh, let cached, !cached.metadata.isExpired {
        if ttl != cached.metadata.ttl { try? Keychain.touch(reference, ttl: ttl) }
        let value = try Enclave.open(cached.ciphertext, with: try Enclave.loadOrCreateKey())
        guard let text = String(data: value, encoding: .utf8) else {
            fail("cached value for \(reference) is not UTF-8")
        }
        print(text, terminator: "")
        return
    }

    let value = fetch(reference)
    guard !value.isEmpty else { fail("\(reference) returned an empty value") }
    let key = try Enclave.loadOrCreateKey()
    let ciphertext = try Enclave.seal(Data(value.utf8), to: key.publicKey)
    try Keychain.save(reference, ciphertext: ciphertext, metadata: CacheMetadata(ttl: ttl))
    print(value, terminator: "")
}

func commandList() throws {
    let entries = try Keychain.list().sorted { $0.ref < $1.ref }
    if entries.isEmpty {
        print("nothing cached")
        return
    }
    for entry in entries {
        let remaining = entry.metadata.isExpired ? "expired" : "\(entry.metadata.remaining)s left"
        print("\(entry.ref.padding(toLength: max(48, entry.ref.count), withPad: " ", startingAt: 0))  \(remaining)")
    }
}

func commandClear(_ arguments: [String]) throws {
    if let raw = arguments.first {
        let reference = resolveReference(raw)
        try Keychain.delete(reference)
        print("cleared \(reference)")
        return
    }
    print("cleared \(try Keychain.deleteAll()) entries")
}

func commandStatus() throws {
    print("secure enclave: \(SecureEnclave.isAvailable ? "available" : "unavailable")")
    print("key:            \(FileManager.default.fileExists(atPath: keyFilePath.path) ? keyFilePath.path : "not created yet")")
    print("cached:         \(try Keychain.list().count) entries")
}

func printUsage() {
    print("""
    usage: secrets <command> [arguments]

      read <ref> [--ttl SECONDS] [--refresh]   print a secret, caching it for the TTL
      list                                     what is cached, and for how much longer
      clear [<ref>]                            drop one cached entry, or all of them
      status                                   Secure Enclave, key file, cache size

    references:
      op://vault/item/field             op read
      lpass://Group/Item[?field=f]      lpass show --password, or --field=f
      keychain://service[/account]      security find-generic-password -w
      cmd://<shell command>             /bin/sh -c

    A bare name is appended to $SECRETS_DEFAULT_REF.
    """)
}

// MARK: - Entry point

setbuf(stdout, nil)

let arguments = Array(CommandLine.arguments.dropFirst())
guard let command = arguments.first else {
    printUsage()
    exit(0)
}

do {
    switch command {
    case "read":
        try commandRead(Array(arguments.dropFirst()))
    case "list", "ls":
        try commandList()
    case "clear":
        try commandClear(Array(arguments.dropFirst()))
    case "status":
        try commandStatus()
    case "help", "-h", "--help":
        printUsage()
    default:
        fail("unknown command '\(command)' (try: secrets help)")
    }
} catch let failure as Failure {
    fail(failure.description)
} catch {
    fail(error.localizedDescription)
}
