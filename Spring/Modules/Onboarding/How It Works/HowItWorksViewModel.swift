//
//  HowItWorksViewModel.swift
//  Spring
//
//  Created by Thuyen Truong on 2/27/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class HowItWorksViewModel: ViewModel {
    // MARK: - Properties
    static var AccountServiceBase: AccountServiceDelegate.Type = AccountService.self
    static var FbmAccountDataEngineBase: FbmAccountDataEngineDelegate.Type = FbmAccountDataEngine.self

    // MARK: - Output
    let signUpResultSubject = PublishSubject<Event<Never>>()

    func signUp() {
        loadingState.onNext(.loading)

        Self.AccountServiceBase.rxCreateAndSetupNewAccountIfNotExist()
            .andThen(FbmAccountDataEngine.create().asCompletable())
            .catchError { (error) -> Completable in
                if let error = error as? ServerAPIError, error.code == .AccountHasTaken {
                    return Completable.empty()
                }

                return Completable.error(error)
        }
        .andThen(Self.FbmAccountDataEngineBase.fetchOverallArchiveStatus())
        .flatMapCompletable { (archiveStatus) -> Completable in
            Global.current.userDefault?.latestArchiveStatus = archiveStatus?.rawValue
            return Completable.empty()
        }
        .asObservable()
        .materialize().bind { [weak self] in
            loadingState.onNext(.hide)
            self?.signUpResultSubject.onNext($0)
        }
        .disposed(by: disposeBag)
    }
}
