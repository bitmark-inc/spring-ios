//
//  DeleteAccountViewModel.swift
//  Spring
//
//  Created by Thuyen Truong on 2/10/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Intercom
import WebKit
import OneSignal

class DeleteAccountViewModel: ViewModel {

    // MARK: - Outputs
    var deleteAccountResultSubject = PublishSubject<Event<Never>>()

    func deleteAccount() {
        FbmAccountService.deleteMe()
            .subscribe(onCompleted: { [weak self] in
                self?.deleteAccountInDevice()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                if let error = error as? ServerAPIError {
                    switch error.code {
                    case .AccountNotFound:
                        self.deleteAccountInDevice()
                        return
                    default:
                        break
                    }
                }

                self.deleteAccountResultSubject.onNext(.error(error))
            })
            .disposed(by: disposeBag)
    }

    fileprivate func deleteAccountInDevice() {
        do {
            try Global.current.removeCurrentAccount()
            deleteAccountResultSubject.onNext(.completed)
        } catch {
            deleteAccountResultSubject.onNext(.error(error))
        }
    }
}
