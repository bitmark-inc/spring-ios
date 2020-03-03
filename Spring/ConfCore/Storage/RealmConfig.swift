//
//  RealmConfig.swift
//  Spring
//
//  Created by Thuyen Truong on 7/14/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

enum RealmConfig {

    static func setupDBForCurrentAccount() throws {
        guard let accountNumber = Global.current.account?.getAccountNumber() else { return }

        _ = try RealmConfig.user(accountNumber).configuration()
    }

    static func currentRealm() throws -> Realm {
        guard let accountNumber = Global.current.account?.getAccountNumber() else {
            throw AppError.emptyCurrentAccount
        }
        let realmconfig = RealmConfig.user(accountNumber)
        let userConfiguration = try realmconfig.configuration()
        Global.log.debug("UserRealm: \(userConfiguration)")

        do {
            return try Realm(configuration: userConfiguration)
        } catch {
            // Remove current realm file to make realm recreate another file with new schema
            Global.log.debug("[] renew realm file when migration requires")
            try realmconfig.deleteCurrentRealmFile()
            return try Realm(configuration: userConfiguration)
        }
    }

    static func globalRealm() throws -> Realm {
        let realmconfig = RealmConfig.anonymous
        let configuration = try realmconfig.configuration()
        Global.log.debug("globalRealm: \(configuration)")

        do {
            return try Realm(configuration: configuration)
        } catch {
            // Remove current realm file to make realm recreate another file with new schema
            Global.log.debug("[] renew realm file when migration requires")
            try realmconfig.deleteCurrentRealmFile()
            return try Realm(configuration: configuration)
        }
    }

    static func rxCurrentRealm() -> Single<Realm> {
        Single.deferred {
            do {
                return Single.just(try currentRealm())
            } catch {
                return Single.error(error)
            }
        }
    }

    case anonymous
    case user(String)

    func configuration() throws -> Realm.Configuration {
        var fileURL: URL!
        let encryptionKeyData: Data!

        switch self {
        case .anonymous:
            fileURL = dbDirectoryURL().appendingPathComponent("data.realm")
            encryptionKeyData = try getKey()

        case .user(let accountNumber):
            fileURL = dbDirectoryURL(for: accountNumber).appendingPathComponent("\(accountNumber).realm")
            encryptionKeyData = try getKey(for: accountNumber)
        }

        return Realm.Configuration(
            fileURL: fileURL,
            encryptionKey: encryptionKeyData,
            schemaVersion: 2,
            migrationBlock: { (migration, oldSchemaVersion) in
                // nothing to do; The addition of properties can be handled automatically
            }
        )
    }

    private func deleteCurrentRealmFile() throws {
        var fileURL: URL!
        switch self {
        case .anonymous:
            fileURL = dbDirectoryURL().appendingPathComponent("data.realm")
        case .user(let accountNumber):
            fileURL = dbDirectoryURL(for: accountNumber).appendingPathComponent("\(accountNumber).realm")
        }

        try FileManager.default.removeItem(at: fileURL)
    }

    static func removeRealm(of accountNumber: String) throws {
        guard let realmURL = try Self.user(accountNumber).configuration().fileURL else { return }
        let realmURLs = [
            realmURL,
            realmURL.appendingPathExtension("lock"),
            realmURL.appendingPathExtension("note"),
            realmURL.appendingPathExtension("management")
        ]

        for URL in realmURLs {
            try FileManager.default.removeItem(at: URL)
        }

        try KeychainStore.removeEncryptedDBKeyFromKeychain(for: accountNumber)
    }

    fileprivate func dbDirectoryURL(for accountNumber: String = "") -> URL {
        Global.log.debug("[start] dbDirectoryURL")
        let dbDirectory = FileManager.databaseDirectoryURL

        do {
            if KeychainStore.getEncryptedDBKeyFromKeychain(for: accountNumber) == nil && FileManager.default.fileExists(atPath: dbDirectory.path) {
                try FileManager.default.removeItem(at: dbDirectory)
            }

            if !FileManager.default.fileExists(atPath: dbDirectory.path) {
                try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
                try FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: dbDirectory.path)
            }
        } catch {
            Global.log.error(error)
        }

        Global.log.debug("[done] dbDirectoryURL")
        return dbDirectory
    }

    // Reference: https://realm.io/docs/swift/latest/#encryption
    fileprivate func getKey(for accountNumber: String = "") throws -> Data {
        guard let encryptedDBKey = KeychainStore.getEncryptedDBKeyFromKeychain(for: accountNumber) else {
            #if targetEnvironment(simulator)
            let key = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ012345678901".data(using: .utf8)!
            #else
            var key = Data(count: 64)
            _ = key.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) -> Void in
                guard let pointer = ptr.bindMemory(to: UInt8.self).baseAddress else { return }
                _ = SecRandomCopyBytes(kSecRandomDefault, 64, pointer)
            })
            #endif

            try KeychainStore.saveEncryptedDBKeyToKeychain(key, for: accountNumber)
            return key
        }

        return encryptedDBKey
    }
}
