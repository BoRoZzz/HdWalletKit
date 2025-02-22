import Foundation

public final class HDKeychain {
    let privateKey: HDPrivateKey

    public init(privateKey: HDPrivateKey) {
        self.privateKey = privateKey
    }

    public convenience init(seed: Data, xPrivKey: UInt32) {
        self.init(privateKey: HDPrivateKey(seed: seed, xPrivKey: xPrivKey))
    }

    /// Parses the BIP32 path and derives the chain of keychains accordingly.
    /// Path syntax: (m?/)?([0-9]+'?(/[0-9]+'?)*)?
    /// The following paths are valid:
    ///
    /// "" (root key)
    /// "m" (root key)
    /// "/" (root key)
    /// "m/0'" (hardened child #0 of the root key)
    /// "/0'" (hardened child #0 of the root key)
    /// "0'" (hardened child #0 of the root key)
    /// "m/44'/1'/2'" (BIP44 testnet account #2)
    /// "/44'/1'/2'" (BIP44 testnet account #2)
    /// "44'/1'/2'" (BIP44 testnet account #2)
    ///
    /// The following paths are invalid:
    ///
    /// "m / 0 / 1" (contains spaces)
    /// "m/b/c" (alphabetical characters instead of numerical indexes)
    /// "m/1.2^3" (contains illegal characters)
    public func derivedKey(path: String) throws -> HDPrivateKey {
        var key = privateKey

        var path = path
        if path == "m" || path == "/" || path == "" {
            return key
        }
        if path.contains("m/") {
            path = String(path.dropFirst(2))
        }
        for chunk in path.split(separator: "/") {
            var hardened = false
            var indexText = chunk
            if chunk.contains("'") {
                hardened = true
                indexText = indexText.dropLast()
            }
            guard let index = UInt32(indexText) else {
                throw DerivationError.invalidPath
            }
            key = try key.derived(at: index, hardened: hardened)
        }
        return key
    }

    func derivedNonHardenedPublicKeys(path: String, indices: Range<UInt32>) throws -> [HDPublicKey] {
        guard indices.count > 0 else {
            return []
        }

        let key = try derivedKey(path: path)

        return try key.derivedNonHardenedPublicKeys(at: indices)
    }

}
