//
//  RequestDataViewModel.swift
//  Spring
//
//  Created by thuyentruong on 11/21/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import OneSignal

enum Mission {
    case requestData
    case checkRequestedData
    case downloadData
    case getCategories
}

class RequestDataViewModel: ViewModel {

    // MARK: - Properties
    var missions = [Mission]()
    static var AccountServiceBase: AccountServiceDelegate.Type = AccountService.self
    static var FBArchiveServiceBase: FBArchiveServiceDelegate.Type = FBArchiveService.self

    // MARK: - Output
    let fbScriptsRelay = BehaviorRelay<[FBScript]>(value: [])
    let fbScriptResultSubject = PublishSubject<Event<Void>>()
    let signUpAndSubmitArchiveResultSubject = PublishSubject<Event<Never>>()

    init(missions: [Mission]) {
        super.init()
        self.missions = missions

        self.setup()
    }

    func setup() {
        ServerAssetsService.getFBAutomation()
            .subscribe(onSuccess: { [weak self] (fbScripts) in
                self?.fbScriptsRelay.accept(fbScripts)
            },
            onError: { [weak self] (error) in
                self?.fbScriptResultSubject.onNext(Event.error(error))
            })
            .disposed(by: disposeBag)

        signUpAndSubmitArchiveResultSubject
            .filter({ $0.isCompleted })
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self, let adsCategories = UserDefaults.standard.fbCategoriesInfo else {
                    return
                }

                _ = self.storeAdsCategoriesInfo(adsCategories)
                    .subscribe(onCompleted: {
                        Global.log.info("[done] store UserInfo - adsCategory")
                        UserDefaults.standard.fbCategoriesInfo = nil
                    }, onError: { (error) in
                        Global.log.error(error)
                    })
            })
            .disposed(by: disposeBag)
    }

    func signUpAndSubmitFBArchive(headers: [String: String], archiveURL: URL, rawCookie: String) {
        loadingState.onNext(.loading)

        let createdAccounCompletable = Completable.deferred {
            if Global.current.account != nil {
                return Completable.empty()
            } else {
                return Self.AccountServiceBase.rxCreateNewAccount()
                    .flatMapCompletable({
                        Global.current.account = $0
                        Self.AccountServiceBase.registerIntercom(for: $0.getAccountNumber())
                        return Global.current.setupCoreData()
                    })
            }
        }

        let registerOneSignalNotificationCompletable = Completable.deferred {
            guard let accountNumber = Global.current.account?.getAccountNumber() else {
                return Completable.never()
            }

            guard UserDefaults.standard.enablePushNotification else {
                return Completable.empty()
            }

            return self.registerOneSignal(accountNumber: accountNumber)
        }

        let fbArchiveCreatedAtTime: Date!
        if let fbArchiveCreatedAt = UserDefaults.standard.FBArchiveCreatedAt {
            fbArchiveCreatedAtTime = fbArchiveCreatedAt
        } else {
            fbArchiveCreatedAtTime = Date()
            Global.log.error(AppError.emptyFBArchiveCreatedAtInUserDefaults)
        }

        createdAccounCompletable
            .andThen(FbmAccountDataEngine.rx.create().asCompletable())
            .catchError { (error) -> Completable in
                if let error = error as? ServerAPIError, error.code == .AccountHasTaken {
                    return Completable.empty()
                }

                return Completable.error(error)
            }
            .andThen(registerOneSignalNotificationCompletable)
            .andThen(
                Self.FBArchiveServiceBase.submit(
                    headers: headers,
                    fileURL: archiveURL.absoluteString,
                    rawCookie: rawCookie,
                    startedAt: nil,
                    endedAt: fbArchiveCreatedAtTime))
            .asObservable()
            .materialize().bind { [weak self] in
                loadingState.onNext(.hide)
                self?.signUpAndSubmitArchiveResultSubject.onNext($0)
            }
            .disposed(by: disposeBag)
    }

    func storeAdsCategoriesInfo(_ adsCategories: [String]) -> Completable {
        do {
            let userInfo = try UserInfo(key: .adsCategory, value: adsCategories)
            return Storage.store(userInfo)
        } catch {
            return Completable.error(error)
        }
    }
    
    fileprivate func registerOneSignal(accountNumber: String) -> Completable {
        Global.log.info("[process] registerOneSignal: \(accountNumber)")
        OneSignal.promptForPushNotifications(userResponse: { _ in
          OneSignal.sendTags([
            Constant.OneSignalTag.key: accountNumber
          ])
        })

        return Completable.empty()
    }
}
