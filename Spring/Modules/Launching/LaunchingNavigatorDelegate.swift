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
        // **** When Data is Requesting
        // - user click notification: make animation to download Archive
        // - user enter the app:      go to check now screen
        if UserDefaults.standard.FBArchiveCreatedAt != nil  { // data is requesting
            loadingState.onNext(.hide)
            if Global.current.didUserTapNotification {
                Global.current.didUserTapNotification = false
                gotoDownloadFBArchiveScreen()
            } else {
                gotoDataRequestedWithCheckButtonScreen()
            }
            return
        }

        // *** When user doesn't log in (and no requesting data)
        if Global.current.account == nil {
            loadingState.onNext(.hide)
            gotoSignInWallScreen()
            return
        }

        // *** user logged in
        // - no connect Spring; no data requesting: goto HowItWork Screen
        // - connected Spring: .checkArchivesStatusToNavigate()
        FbmAccountDataEngine.fetchCurrentFbmAccount()
            .subscribe(onSuccess: {  [weak self] (_) in
                self?.checkArchivesStatusToNavigate()

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

    fileprivate func checkArchivesStatusToNavigate() {

        // ** archiveStatus is nil - no archives: goto SignInWall / HowItWorks Screen (this case is coverred in case, shouldn't happen)
        // ** archiveStatus is present - archive uploaded:
        // ---- goto MainScreen with showing appArchiveStatus box
        // ---- when adsCategories is empty, goto get it first
        func navigateWithArchiveStatus(_ archiveStatus: ArchiveStatus?) {
            if archiveStatus != nil {
                if InsightDataEngine.existsAdsCategories() {
                    navigator.show(segue: .hometabs(isArchiveStatusBoxShowed: true), sender: self, transition: .replace(type: .none))
                } else {
                    let viewModel = RequestDataViewModel(missions: [.getCategories])
                    navigator.show(segue: .requestData(viewModel: viewModel), sender: self, transition: .replace(type: .none))
                }
            } else {
                Global.current.account == nil ? gotoSignInWallScreen() : gotoTrustIsCritialScreen()
            }
        }

        // sync latestArchiveStatus from remoting
        // ---- if there are noInternetConnection, make offline version by using localLatestArchiveStatus
        FbmAccountDataEngine.fetchOverallArchiveStatus()
            .subscribe(onSuccess: { (archiveStatus) in
                loadingState.onNext(.hide)
                Global.current.userDefault?.latestArchiveStatus = archiveStatus?.rawValue
                navigateWithArchiveStatus(archiveStatus)

            }, onError: { [weak self] (error) in
                loadingState.onNext(.hide)
                guard let self = self else { return }
                if AppError.errorByNetworkConnection(error) {
                    let archiveStatus = ArchiveStatus(rawValue: Global.current.userDefault?.latestArchiveStatus ?? "")
                    navigateWithArchiveStatus(archiveStatus)
                    return
                }

                guard !self.showIfRequireUpdateVersion(with: error) else { return }

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

    fileprivate func gotoDownloadFBArchiveScreen() {
        let viewModel = RequestDataViewModel(missions: [.getCategories, .downloadData])
        navigator.show(segue: .requestData(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoDataRequestedWithCheckButtonScreen() {
        navigator.show(segue: .checkDataRequested, sender: self, transition: .replace(type: .none))
    }
}
