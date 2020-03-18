//
//  LaunchingNavigatorDelegate.swift
//  Spring
//
//  Created by Thuyen Truong on 1/14/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import RxSwift
import RxCocoa
import FlexLayout

protocol LaunchingNavigatorDelegate: ViewController {
    func loadAndNavigate()
    func navigate()
}

extension LaunchingNavigatorDelegate {

    func loadAndNavigate() {
        let existsCurrentAccountSingle = Single<Account?>.deferred {
            if let account = Global.current.account {
                return Single.just(account)
            } else {
                return AccountService.rxExistsCurrentAccount()
            }
        }

        existsCurrentAccountSingle
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (account) in
                guard let self = self else { return }

                do {
                    if let account = account {
                        Global.current.account = account

                        AccountService.registerIntercom(for: account.getAccountNumber())
                        SettingsBundle.setAccountNumber(accountNumber: account.getAccountNumber())
                        try RealmConfig.setupDBForCurrentAccount()
                    }

                    self.navigate()
                } catch {
                    Global.log.error(error)
                }

            }, onError: { (error) in
                loadingState.onNext(.hide)
                _ = ErrorAlert.showAuthenticationRequiredAlert { [weak self] in
                    self?.loadAndNavigate()
                }
            })
            .disposed(by: disposeBag)
    }

    func navigate() {
        // *** When user doesn't log in (and no requesting data)
        if Global.current.account == nil {
            loadingState.onNext(.hide)
            gotoSignInWallScreen()
            return
        }

        // *** user logged in
        // - requesting fbArchive
        if GetYourData.standard.requestedAtRelay.value != nil {
            loadingState.onNext(.hide)
            gotoCheckDataRequestedScreen()
            return
        }

        // - no connect Spring; no data requesting: goto HowItWork Screen
        // - connected Spring: .gotoHomeTab()
        FbmAccountDataEngine.syncMe()
            .andThen(Single.just(FbmAccountDataEngine.fetchMe()))
            .subscribe(onSuccess: { [weak self] (_) in
                guard let self = self else { return }
                loadingState.onNext(.hide)
                self.gotoHomeTab()

            }, onError: { [weak self] (error) in
                loadingState.onNext(.hide)
                guard let self = self,
                    !AppError.errorByNetworkConnection(error),
                    !self.showIfRequireUpdateVersion(with: error) else {
                        return
                }

                // is not FBM's Account => link to HowItWorks
                if let error = error as? ServerAPIError {
                    switch error.code {
                    case .AccountNotFound:
                        self.gotoTrustIsCritialScreen()
                        return
                    default:
                        break
                    }
                }

                Global.log.error(error)
                self.showErrorAlertWithSupport(message: R.string.error.system())
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Navigator
extension LaunchingNavigatorDelegate {
    fileprivate func gotoSignInWallScreen() {
        let viewModel = SignInWallViewModel()
        navigator.show(segue: .signInWall(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoTrustIsCritialScreen() {
        navigator.show(segue: .trustIsCritical(buttonItemType: .none), sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoHomeTab() {
        navigator.show(segue: .hometabs(missions: []), sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoCheckDataRequestedScreen() {
        navigator.show(segue: .checkDataRequested, sender: self, transition: .replace(type: .none))
    }
}
