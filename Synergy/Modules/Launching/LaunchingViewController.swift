//
//  LaunchingViewController.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import RxSwift
import RxCocoa
import FlexLayout

class LaunchingViewController: ViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let viewModel = viewModel as? LaunchingViewModel else { return }

        // NOTE: For first demo, make quick Onboarding Flow
        AccountService.rx.existsCurrentAccount()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { (account) in
                Global.current.account = account

                if Global.current.account != nil {
                    viewModel.gotoMainScreen()
                } else {
                    viewModel.gotoSignInWallScreen()
                }
            }, onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: disposeBag)

        return
        // END

        if UserDefaults.standard.isCreatingFBArchive {
            viewModel.gotoDownloadFBArchiveScreen()
            return
        }

        AccountService.rx.existsCurrentAccount()
            .observeOn(MainScheduler.instance)
            .flatMapCompletable { [weak self] in
                guard let self = self else { return Completable.never() }
                return try self.prepareAndGotoNext(account: $0)
            }
            .subscribe(onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: disposeBag)
    }

    func prepareAndGotoNext(account: Account?) throws -> Completable {
        guard let viewModel = viewModel as? LaunchingViewModel else {
            return Completable.never()
        }

        if let account = account {
            Global.current.account = account
            try RealmConfig.setupDBForCurrentAccount()

            FbmAccountDataEngine.rx.fetchCurrentFbmAccount()
                .subscribe(onSuccess: { (_) in
                    // TODO: Check if finish generating data's insights
                    viewModel.gotoDataGeneratingScreen()
                }, onError: { [weak self] (error) in
                    // is not FBM's Account => link to HowItWorks
                    if let error = error as? ServerAPIError {
                        switch error.code {
                        case .AccountNotFound:
                             viewModel.gotoHowItWorksScreen()
                            return
                        default:
                            break
                        }
                    }

                    guard !AppError.errorByNetworkConnection(error) else { return }
                    Global.log.error(error)
                    self?.showErrorAlertWithSupport(message: R.string.error.system())
                })
                .disposed(by: disposeBag)
        } else {
            viewModel.gotoSignInWallScreen()
        }

        return Completable.empty()
    }

    override func setupViews() {
        setupBackground(image: R.image.onboardingSplash())
        super.setupViews()

        // *** Setup subviews ***
        let titleScreen = Label()
        titleScreen.applyLight(
            text: R.string.phrase.launchName().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(150)))
        titleScreen.adjustsFontSizeToFitWidth = true

        let descriptionLabel = Label()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.applyLight(
            text: R.string.phrase.launchDescription(),
            font: R.font.atlasGroteskLight(size: Size.ds(22)),
            lineHeight: 1.1)

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem(titleScreen).marginTop(50%).width(100%)
            flex.addItem(descriptionLabel).marginTop(Size.dh(10))
        }
    }
}
