//
//  Global.swift
//  Spring
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxSwiftExt
import BitmarkSDK
import Moya
import Intercom
import WebKit
import OneSignal
import SwiftEntryKit

class Global {
    static var current = Global()
    static let `default` = current
    static let backgroundErrorSubject = PublishSubject<Error>()
    static let disposeBag = DisposeBag()

    var account: Account?
    var currency: Currency?
    var userDefault: UserDefaults? {
        guard let accountNumber = account?.getAccountNumber()
            else { return nil }
        return UserDefaults.userStandard(for: accountNumber)
    }

    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        //    let dateFormat = ISO8601DateFormatter()
        let dateFormat = DateFormatter()
        dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormat.dateFormat = "yyyy-MM-dd'T'H:m:ss.SSSS'Z"

        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            guard let date = dateFormat.date(from: dateString) else {
                throw "cannot decode date string \(dateString)"
            }
            return date
        })
        return decoder
    }()

    func setupCoreData() -> Completable {
        return Completable.create { (event) -> Disposable in
            guard let currentAccount = Global.current.account else {
                event(.error(AppError.emptyCurrentAccount))
                return Disposables.create()
            }

            do {
                try RealmConfig.setupDBForCurrentAccount()
                try KeychainStore.saveToKeychain(currentAccount.seed.core, isSecured: false)
                event(.completed)
            } catch {
                event(.error(error))
            }
            return Disposables.create()
        }
    }

    func removeCurrentAccount() throws {
        guard let account = Global.current.account else {
            throw AppError.emptyCurrentAccount
        }

        try KeychainStore.removeSeedCoreFromKeychain()

        // clear user data
        try FileManager.default.removeItem(at: FileManager.filesDocumentDirectoryURL)
        try RealmConfig.removeRealm(of: account.getAccountNumber())
        UserDefaults.standard.clickedIncreasePrivacyURLs = nil
        UserDefaults.standard.FBArchiveCreatedAt = nil
        Global.current.userDefault?.latestAppArchiveStatus = []
        BackgroundTaskManager.shared.urlSession(identifier: SessionIdentifier.upload.rawValue).invalidateAndCancel()

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
        BackgroundTaskManager.shared = BackgroundTaskManager()

        Intercom.logout()
        OneSignal.setSubscription(false)
        OneSignal.deleteTag(Constant.OneSignalTag.key)
        ErrorReporting.setUser(bitmarkAccountNumber: nil)
    }

    static func pollingSyncAppArchiveStatus() {
        // avoid override the tracking status in local
        let currentState = AppArchiveStatus.currentState.value
        guard currentState.isEmpty || !AppArchiveStatus.isRequestingPoint else {
            return
        }

        func pollingFunction() -> Observable<Void> {
            return ArchiveDataEngine.fetchAppArchiveStatus()
                .do(onSuccess: {
                    Global.current.userDefault?.latestAppArchiveStatus = $0
                })
                .asObservable()
                .flatMap({ (appArchiveStatuses) -> Observable<Void> in
                    return appArchiveStatuses.contains(where: { $0 == .processing }) ?
                        Observable.error(AppError.archiveIsNotProcessed) :
                        Observable.empty()
                })
        }

        pollingFunction()
            .retry(.delayed(maxCount: 1000, time: 5 * 60))
            .subscribe()
            .disposed(by: disposeBag)
    }

    let networkLoggerPlugin: [PluginType] = [
        NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(output: { (_, items) in
            for item in items {
                Global.log.info(item)
            }
        })),
        MoyaAuthPlugin(tokenClosure: {
            return AuthService.shared.auth?.jwtToken
        }),
        MoyaVersionPlugin()
    ]

    // *** UI ***
    static var infoEKAttributes: EKAttributes = {
        var attributes = EKAttributes.bottomToast
        attributes.entryBackground = .color(color: .white)
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.3), scale: .init(from: 1, to: 0.7, duration: 0.7)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 10, offset: .zero))
        attributes.displayDuration = 1.5
        return attributes
    }()

}

enum AppError: Error {
    case emptyLocal
    case emptyCurrentAccount
    case emptyUserDefaults
    case emptyJWT
    case emptyFBArchiveCreatedAtInUserDefaults
    case emptyCredentialKeychain
    case incorrectLocal
    case incorrectThread
    case incorrectMetadataLocal
    case missingFileNameFromServer
    case noInternetConnection
    case incorrectPostFilter
    case incorrectReactionFilter
    case requireAppUpdate(updateURL: URL)
    case loginFailedIsNotDetected
    case incorrectEmptyRealmObject
    case biometricNotConfigured
    case biometricError
    case didRemoteQuery
    case archiveIsNotProcessed
    case invalidPresignedURL
    case fbRequiredPageIsNotReady

    static func errorByNetworkConnection(_ error: Error) -> Bool {
        guard let error = error as? Self else { return false }
        switch error {
        case .noInternetConnection:
            return true
        default:
            return false
        }
    }
}

enum AccountError: Error {
    case invalidRecoveryKey
}

extension UserDefaults {
    static func userStandard(for number: String) -> UserDefaults? {
        return UserDefaults(suiteName: number)
    }

    var enteredBackgroundTime: Date? {
        get { return date(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    var clickedIncreasePrivacyURLs: [String]? {
        get { return stringArray(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    var showedInvalidArchiveIDs: [Int64] {
        get { return (array(forKey: #function) as? [Int64]) ?? [] }
        set { set(newValue, forKey: #function) }
    }

    var FBArchiveCreatedAt: Date? {
        get { return date(forKey: #function) }
        set {
            GetYourData.standard.requestedAtRelay.accept(newValue)
            set(newValue, forKey: #function)
        }
    }

    // MARK: - Settings
    var appVersion: String? {
        get { return string(forKey: "version_preference") }
        set { set(newValue, forKey: "version_preference") }
    }

    var accountNumber: String? {
        get { return string(forKey: "accountNumber_preference") }
        set { set(newValue, forKey: "accountNumber_preference") }
    }

    // Per Account
    var latestAppArchiveStatus: [AppArchiveStatus] {
        get {
            let archiveStatusStrings = stringArray(forKey: #function) ?? []
            return archiveStatusStrings.compactMap { AppArchiveStatus(rawValue: $0) }
        }
        set {
            let archiveStatusStrings = newValue.compactMap { $0.rawValue }
            set(archiveStatusStrings, forKey: #function)
        }
    }

    var isAccountSecured: Bool {
        get { return bool(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }
}
