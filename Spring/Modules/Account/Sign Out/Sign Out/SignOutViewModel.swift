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

class SignOutViewModel: ConfirmRecoveryKeyViewModel {

    // MARK: - Outputs
    var signOutAccountResultSubject = PublishSubject<Event<Never>>()

    // MARK: - Handlers
    func signOutAccount() {
        do {
            guard try validRecoveryKey() else {
                signOutAccountResultSubject.onNext(
                    Event.error(AccountError.invalidRecoveryKey)
                )
                return
            }

            try Global.current.removeCurrentAccount()
            signOutAccountResultSubject.onNext(.completed)
        } catch {
            signOutAccountResultSubject.onNext(.error(error))
        }
    }

    func validRecoveryKey() throws -> Bool {
        guard let currentAccount = Global.current.account else { throw AppError.emptyCurrentAccount }

        let currentRecoveryKey = try currentAccount.getRecoverPhrase(language: .english)
        return recoveryKeyRelay.value == currentRecoveryKey
    }
}
