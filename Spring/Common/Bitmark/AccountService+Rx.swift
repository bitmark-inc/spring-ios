//
//  Account+Rx.swift
//  Spring
//
//  Created by thuyentruong on 11/21/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import BitmarkSDK
import RxSwift
import Intercom

protocol AccountServiceDelegate {
    static func registerIntercom(for accountNumber: String?, metadata: [String: String])

    // Reactive
    static func rxCreateAndSetupNewAccountIfNotExist() -> Completable
    static func rxCreateNewAccount() -> Single<Account>
    static func rxExistsCurrentAccount() -> Single<Account?>
    static func rxGetAccount(phrases: [String]) -> Single<Account>
}

extension AccountServiceDelegate {
    static func registerIntercom(for accountNumber: String?, metadata: [String: String] = [:]) {
        return registerIntercom(for: accountNumber, metadata: metadata)
    }

    static func rxCreateAndSetupNewAccountIfNotExist() -> Completable {
        Completable.deferred {
            guard Global.current.account == nil else {
                return Completable.empty()
            }
            return rxCreateNewAccount()
                .flatMapCompletable({
                    Global.current.account = $0
                    registerIntercom(for: $0.getAccountNumber())
                    return Global.current.setupCoreData()
                })
        }
    }
}

class AccountService: AccountServiceDelegate {
    static func registerIntercom(for accountNumber: String?, metadata: [String: String] = [:]) {
        Global.log.info("[start] registerIntercom")
        
        Intercom.logout()
        
        if let accountNumber = accountNumber {
            let intercomUserID = "\(Constant.appName)_ios_\(accountNumber.hexDecodedData.sha3(length: 256).hexEncodedString)"
            Intercom.registerUser(withUserId: intercomUserID)
        } else {
            Intercom.registerUnidentifiedUser()
        }
        
        let userAttributes = ICMUserAttributes()
        
        var metadata = metadata
        metadata["Service"] = (Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String) ?? ""
        userAttributes.customAttributes = metadata
        
        Intercom.updateUser(userAttributes)
        Global.log.info("[done] registerIntercom")
    }

    static func rxCreateNewAccount() -> Single<Account> {
        Global.log.info("[start] createNewAccount")

        return Single.just(()).map { try Account() }
    }

    static func rxExistsCurrentAccount() -> Single<Account?> {
        Global.log.info("[start] existsCurrentAccount")

        return KeychainStore.getSeedDataFromKeychain()
            .flatMap({ (seedCore) -> Single<Account?> in
                guard let seedCore = seedCore else { return Single.just(nil) }
                do {
                    let seed = try Seed.fromCore(seedCore, version: .v2)
                    return Single.just(try Account(seed: seed))
                } catch {
                    return Single.error(error)
                }
            })
    }

    static func rxGetAccount(phrases: [String]) -> Single<Account> {
        do {
            let account = try Account(recoverPhrase: phrases, language: .english)
            return Single.just(account)
        } catch {
            return Single.error(error)
        }
    }
}
