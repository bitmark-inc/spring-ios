//
//  SignOutViewModel.swift
//  Spring
//
//  Created by Thuyen Truong on 12/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Intercom
import WebKit

class SignOutViewModel: ConfirmRecoveryKeyViewModel {

    // MARK: - Outputs
    var signOutAccountResultSubject = PublishSubject<Event<Never>>()

    // MARK: - Handlers
    func signOutAccount() {
        guard let account = Global.current.account else {
            Global.log.error(AppError.emptyCurrentAccount)
            return
        }
        do {
            guard try validRecoveryKey() else {
                signOutAccountResultSubject.onNext(
                    Event.error(AccountError.invalidRecoveryKey)
                )
                return
            }

            try KeychainStore.removeSeedCoreFromKeychain()

            // clear user data
            try FileManager.default.removeItem(at: FileManager.filesDocumentDirectoryURL)
            try RealmConfig.removeRealm(of: account.getAccountNumber())
            UserDefaults.standard.clickedIncreasePrivacyURLs = nil

            // clear user cookie in webview
            HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)

            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
                records.forEach { (record) in
                    WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                }
            }

            // clear settings bundle
            SettingsBundle.setAccountNumber(accountNumber: nil)

            Global.current = Global() // reset local variable
            AuthService.shared = AuthService()
            Intercom.logout()
            ErrorReporting.setUser(bitmarkAccountNumber: nil)

            signOutAccountResultSubject.onNext(Event.completed)
        } catch {
            signOutAccountResultSubject.onNext(Event.error(error))
        }
    }

    func validRecoveryKey() throws -> Bool {
        guard let currentAccount = Global.current.account else { throw AppError.emptyCurrentAccount }

        let currentRecoveryKey = try currentAccount.getRecoverPhrase(language: .english)
        return recoveryKeyRelay.value == currentRecoveryKey
    }
}
