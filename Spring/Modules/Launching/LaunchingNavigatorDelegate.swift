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
    func navigate()
}

extension LaunchingNavigatorDelegate {
    func navigate() {
        AccountService.rx.existsCurrentAccount()
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

                    UserDefaults.standard.FBArchiveCreatedAt != nil ?
                        self.checkToNavigateOnboarding() :
                        self.prepareAndGotoNext(account: account)

                } catch {
                    Global.log.error(error)
                }

            }, onError: { (error) in
                loadingState.onNext(.hide)
                _ = ErrorAlert.showAuthenticationRequiredAlert { [weak self] in
                    self?.navigate()
                }
            })
            .disposed(by: disposeBag)
    }

    fileprivate func checkToNavigateOnboarding() {
        loadingState.onNext(.hide)
        if Global.current.didUserTapNotification {
            Global.current.didUserTapNotification = false
            gotoDownloadFBArchiveScreen()
        } else {
            gotoDataRequestedWithCheckButtonScreen()
        }
    }

    fileprivate func prepareAndGotoNext(account: Account?) {
        if account != nil {
            FbmAccountDataEngine.rx.fetchCurrentFbmAccount()
                .subscribe(onSuccess: {  [weak self] (_) in
                    self?.checkArchivesStatusToNavigate()

                }, onError: { [weak self] (error) in
                    loadingState.onNext(.hide)
                    guard let self = self else { return }
                    guard !AppError.errorByNetworkConnection(error) else { return }
                    guard !self.showIfRequireUpdateVersion(with: error) else { return }

                    // is not FBM's Account => link to HowItWorks
                    if let error = error as? ServerAPIError {
                        switch error.code {
                        case .AccountNotFound:
                             self.gotoHowItWorksScreen()
                            return
                        default:
                            break
                        }
                    }

                    Global.log.error(error)
                    self.showErrorAlertWithSupport(message: R.string.error.system())
                })
                .disposed(by: disposeBag)
        } else {
            loadingState.onNext(.hide)
            gotoSignInWallScreen()
        }
    }

    fileprivate func checkArchivesStatusToNavigate() {
        FbmAccountService.fetchOverallArchiveStatus()
            .subscribe(onSuccess: { [weak self] (archiveStatus) in
                guard let self = self else { return }
                loadingState.onNext(.hide)
                Global.current.userDefault?.latestArchiveStatus = archiveStatus?.rawValue
                self.navigateWithArchiveStatus(archiveStatus)

            }, onError: { [weak self] (error) in
                loadingState.onNext(.hide)
                guard let self = self else { return }
                if AppError.errorByNetworkConnection(error) {
                    let archiveStatus = ArchiveStatus(rawValue: Global.current.userDefault?.latestArchiveStatus ?? "")
                    self.navigateWithArchiveStatus(archiveStatus)
                    return
                }

                guard !self.showIfRequireUpdateVersion(with: error) else { return }

                Global.log.error(error)
                self.showErrorAlertWithSupport(message: R.string.error.system())
            })
            .disposed(by: disposeBag)
    }

    fileprivate func navigateWithArchiveStatus(_ archiveStatus: ArchiveStatus?) {
        if let archiveStatus = archiveStatus {
            if InsightDataEngine.existsAdsCategories() {
                switch archiveStatus {
                case .processed:
                    gotoMainScreen()
                default:
                    gotoDataAnalyzingScreen()
                }
            } else {
                let viewModel = GetYourDataViewModel(missions: [.getCategories])
                navigator.show(segue: .getYourData(viewModel: viewModel), sender: self, transition: .replace(type: .none))
            }
        } else {
            gotoSignInWallScreen()
        }
    }
}

// MARK: - Navigator
extension LaunchingNavigatorDelegate {
    fileprivate func gotoSignInWallScreen() {
        let viewModel = SignInWallViewModel()
        navigator.show(segue: .signInWall(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoHowItWorksScreen() {
        navigator.show(segue: .howItWorks, sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoDownloadFBArchiveScreen() {
        let viewModel = RequestDataViewModel(missions: [.downloadData])
        navigator.show(segue: .requestData(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoMainScreen() {
        navigator.show(segue: .hometabs, sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoDataRequestedWithCheckButtonScreen() {
        let viewModel = DataRequestedViewModel(.checkRequestedData)
        navigator.show(segue: .dataRequested(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoDataAnalyzingScreen() {
        let viewModel = DataAnalyzingViewModel()
        navigator.show(segue: .dataAnalyzing(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }
}
