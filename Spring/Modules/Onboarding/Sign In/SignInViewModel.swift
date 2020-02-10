//
//  SignInViewModel.swift
//  Spring
//
//  Created by Thuyen Truong on 12/31/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import BitmarkSDK
import Intercom

class SignInViewModel: ConfirmRecoveryKeyViewModel {

    // MARK: - Outputs
    var signInResultSubject = PublishSubject<Event<Never>>()

    func signInAccount() {
        Global.log.info("[start] signIn")

        let setupAccountCompletable = Completable.deferred {
            guard let account = Global.current.account else {
                return Completable.never()
            }

            AccountService.registerIntercom(for: account.getAccountNumber())
            SettingsBundle.setAccountNumber(accountNumber: account.getAccountNumber())
            return Global.current.setupCoreData()
        }

        loadingState.onNext(.loading)
        AccountService.rxGetAccount(phrases: recoveryKeyRelay.value)
            .flatMapCompletable { (account) -> Completable in
                Global.current.account = account
                return setupAccountCompletable
            }
            .asObservable()
            .materialize().bind { [weak self] in
                self?.signInResultSubject.onNext($0)
            }
            .disposed(by: disposeBag)
    }
}
