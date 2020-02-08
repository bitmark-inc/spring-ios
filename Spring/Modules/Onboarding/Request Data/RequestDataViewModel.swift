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
    }

    func signUpAndSubmitFBArchive(headers: [String: String], archiveURL: URL, rawCookie: String) {
        loadingState.onNext(.loading)

        let fbArchiveCreatedAtTime: Date!
        if let fbArchiveCreatedAt = UserDefaults.standard.FBArchiveCreatedAt {
            fbArchiveCreatedAtTime = fbArchiveCreatedAt
        } else {
            fbArchiveCreatedAtTime = Date()
            Global.log.error(AppError.emptyFBArchiveCreatedAtInUserDefaults)
        }

        Self.AccountServiceBase.rxCreateAndSetupNewAccountIfNotExist()
            .andThen(FbmAccountDataEngine.rx.create().asCompletable())
            .catchError { (error) -> Completable in
                if let error = error as? ServerAPIError, error.code == .AccountHasTaken {
                    return Completable.empty()
                }

                return Completable.error(error)
            }
            .andThen(
                Self.FBArchiveServiceBase.submit(
                    headers: headers,
                    fileURL: archiveURL.absoluteString,
                    rawCookie: rawCookie,
                    startedAt: nil,
                    endedAt: fbArchiveCreatedAtTime))
            .andThen(FbmAccountService.fetchOverallArchiveStatus())
            .flatMapCompletable { (archiveStatus) -> Completable in
                Global.current.userDefault?.latestArchiveStatus = archiveStatus?.rawValue
                return Completable.empty()
            }
            .asObservable()
            .materialize().bind { [weak self] in
                loadingState.onNext(.hide)
                self?.signUpAndSubmitArchiveResultSubject.onNext($0)
            }
            .disposed(by: disposeBag)
    }

    func signUpAndStoreAdsCategoriesInfo(_ adsCategories: [String]) -> Completable {
        Self.AccountServiceBase.rxCreateAndSetupNewAccountIfNotExist()
            .andThen(Completable.deferred{
                do {
                    let userInfo = try UserInfo(key: .adsCategory, value: adsCategories)
                    return Storage.store(userInfo)
                } catch {
                    return Completable.error(error)
                }
            })
    }
}
