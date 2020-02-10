//
//  Navigator.swift
//  Spring
//
//  Created by Anh Nguyen on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Hero
import SafariServices
import ESTabBarController_swift
import BitmarkSDK

protocol Navigatable {
    var navigator: Navigator! { get set }
}

class Navigator {
    static var `default` = Navigator()

    // MARK: - segues list, all app scenes
    enum Scene {
        case launchingNavigation
        case launching
        case launchingDeeplinkNavigation
        case signInWall(viewModel: SignInWallViewModel)
        case signIn(viewModel: SignInViewModel)
        case trustIsCritical(buttonItemType: ButtonItemType)
        case howItWorks
        case requestData(viewModel: RequestDataViewModel)
        case checkDataRequested
        case safari(URL)
        case safariController(URL)
        case hometabs(isArchiveStatusBoxShowed: Bool)
        case postList(viewModel: PostListViewModel)
        case reactionList(viewModel: ReactionListViewModel)
        case incomeQuestion
        case account(viewModel: AccountViewModel)
        case signOutWarning
        case signOut(viewModel: SignOutViewModel)
        case biometricAuth
        case viewRecoveryKeyWarning
        case viewRecoverykey(viewModel: ViewRecoveryKeyViewModel)
        case increasePrivacyList
        case increasePrivacy(viewModel: IncreasePrivacyViewModel)
        case about
        case faq
        case releaseNote(buttonItemType: ButtonItemType)
    }

    enum Transition {
        case root(in: UIWindow)
        case navigation(type: HeroDefaultAnimationType)
        case customModal(type: HeroDefaultAnimationType)
        case replace(type: HeroDefaultAnimationType)
        case modal
        case detail
        case alert
        case custom
    }

    // MARK: - get a single VC
    func get(segue: Scene) -> UIViewController? {
        switch segue {
        case .launchingNavigation:
            let launchVC = LaunchingViewController()
            return NavigationController(rootViewController: launchVC)

        case .launching: return LaunchingViewController()
        case .launchingDeeplinkNavigation:
            let launchVC = LaunchingDeeplinkViewController()
            return NavigationController(rootViewController: launchVC)

        case .signInWall(let viewModel): return SignInWallViewController(viewModel: viewModel)
        case .signIn(let viewModel): return SignInViewController(viewModel: viewModel)
        case .trustIsCritical(let buttonItemType):
            let trustIsCriticalViewController = TrustIsCriticalViewController()
            trustIsCriticalViewController.buttonItemType = buttonItemType
            return trustIsCriticalViewController

        case .howItWorks: return HowItWorksViewController()
        case .requestData(let viewModel): return RequestDataViewController(viewModel: viewModel)
        case .checkDataRequested: return CheckDataRequestedViewController()
        case .safari(let url):
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return nil

        case .safariController(let url):
            let vc = SFSafariViewController(url: url)
            return vc

        case .hometabs(let isArchiveStatusBoxShowed):
            return HomeTabbarController.tabbarController(isArchiveStatusBoxShowed: isArchiveStatusBoxShowed)
        case .postList(let viewModel): return PostListViewController(viewModel: viewModel)
        case .reactionList(let viewModel): return ReactionListViewController(viewModel: viewModel)
        case .incomeQuestion: return IncomeQuestionViewController()
        case .account(let viewModel):
            let accountViewController = AccountViewController(viewModel: viewModel)
            accountViewController.hidesBottomBarWhenPushed = true
            return accountViewController

        case .signOutWarning, .signOut,
             .biometricAuth,
             .viewRecoveryKeyWarning, .viewRecoverykey,
             .increasePrivacyList, .increasePrivacy,
             .about, .faq, .releaseNote:

            let viewController: UIViewController!
            switch segue {
            case .signOutWarning:                   viewController = SignOutWarningViewController()
            case .signOut(let viewModel):           viewController = SignOutViewController(viewModel: viewModel)
            case .biometricAuth:                    viewController = BiometricAuthViewController()
            case .viewRecoveryKeyWarning:           viewController = ViewRecoveryKeyWarningViewController()
            case .viewRecoverykey(let viewModel):   viewController = ViewRecoveryKeyViewController(viewModel: viewModel)
            case .increasePrivacyList:              viewController = IncreasePrivacyListViewController()
            case .increasePrivacy(let viewModel):   viewController = IncreasePrivacyViewController(viewModel: viewModel)
            case .about:                            viewController = AboutViewController()
            case .faq:                              viewController = FAQViewController()
            case .releaseNote(let buttonItemType):
                let releaseNoteViewController = ReleaseNoteViewController()
                releaseNoteViewController.buttonItemType = buttonItemType
                viewController = releaseNoteViewController
            default:
                viewController = UIViewController()
            }

            viewController.hidesBottomBarWhenPushed = true
            return viewController
        }
    }

    func pop(sender: UIViewController?, toRoot: Bool = false) {
        if toRoot {
            sender?.navigationController?.popToRootViewController(animated: true)
        } else {
            sender?.navigationController?.popViewController()
        }
    }

    func dismiss(sender: UIViewController?) {
        sender?.navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - invoke a single segue
    func show(segue: Scene, sender: UIViewController?, transition: Transition = .navigation(type: .cover(direction: .left))) {
        if let target = get(segue: segue) {
            show(target: target, sender: sender, transition: transition)
        }
    }

    private func show(target: UIViewController, sender: UIViewController?, transition: Transition) {
        switch transition {
        case .root(in: let window):
            window.rootViewController = target
            return
        case .replace(let type):
            guard let rootViewController = Self.getRootViewController() else {
                Global.log.error("rootViewController is empty")
                return
            }

            // replace controllers in navigation stack
            rootViewController.hero.navigationAnimationType = .autoReverse(presenting: type)
            switch type {
            case .none:
                rootViewController.setViewControllers([target], animated: false)
            default:
                rootViewController.setViewControllers([target], animated: true)
            }
            return
        case .custom: return
        default: break
        }

        guard let sender = sender else {
            fatalError("You need to pass in a sender for .navigation or .modal transitions")
        }

        if let nav = sender as? UINavigationController {
            //push root controller on navigation stack
            nav.pushViewController(target, animated: false)
            return
        }

        switch transition {
        case .navigation(let type):
            if let nav = sender.navigationController {
                // push controller to navigation stack
                nav.hero.navigationAnimationType = .autoReverse(presenting: type)
                nav.pushViewController(target, animated: true)
            }
        case .customModal(let type):
            // present modally with custom animation
            DispatchQueue.main.async {
                let nav = NavigationController(rootViewController: target)
                nav.hero.modalAnimationType = .autoReverse(presenting: type)
                sender.present(nav, animated: true, completion: nil)
            }
        case .modal:
            // present modally
            DispatchQueue.main.async {
                let nav = NavigationController(rootViewController: target)
                sender.present(nav, animated: true, completion: nil)
            }
        case .detail:
            DispatchQueue.main.async {
                let nav = NavigationController(rootViewController: target)
                sender.showDetailViewController(nav, sender: nil)
            }
        case .alert:
            DispatchQueue.main.async {
                sender.present(target, animated: true, completion: nil)
            }
        default: break
        }
    }

    static func refreshOnboardingStateIfNeeded() {
        _ = AppVersion.checkAppVersion()
            .observeOn(MainScheduler.instance)
            .subscribe(onCompleted: {
                guard let window = getWindow() else {
                    Global.log.error("window is empty")
                    return
                }

                guard let rootViewController = getRootViewController() else {
                    Global.log.error("rootViewController is empty")
                    return
                }

                // check if scene is on onboarding flow's refresh state
                guard let currentVC = rootViewController.viewControllers.last else { return }

                guard (type(of: currentVC) == HomeTabbarController.self && AppArchiveStatus.currentState != .done)
                    else {
                        return
                }

                Navigator.default.show(segue: .launchingNavigation, sender: nil, transition: .root(in: window))
            }, onError: { (error) in
                if let error = error as? AppError {
                    switch error {
                    case .requireAppUpdate(let updateURL):
                        AppVersion.showAppRequireUpdateAlert(updateURL: updateURL)
                        return
                    case .noInternetConnection:
                        return
                    default:
                        break
                    }
                }

                Global.log.error(error)
            })
    }

    static let requireAuthorizationTime = 30 // minutes
    static var retryAuthenticationAlert: UIAlertController?
    static func evaluatePolicyWhenUserSetEnable(force: Bool = false) {
        if !force {
            guard Global.current.account != nil,
                let enteredBackgroundTime = UserDefaults.standard.enteredBackgroundTime else {
                    return
            }
            guard Global.current.userDefault?.isAccountSecured ?? false else { return }
            guard Date() >= enteredBackgroundTime.adding(.minute, value: requireAuthorizationTime) else { return }
        }

        retryAuthenticationAlert?.dismiss(animated: false, completion: nil)

        _ = AccountService.rxExistsCurrentAccount()
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { (_) in
                Navigator.retryAuthenticationAlert = ErrorAlert.showAuthenticationRequiredAlert {
                    Navigator.evaluatePolicyWhenUserSetEnable(force: true)
                }
            })
    }

    static func getRootViewController() -> NavigationController? {
        return getWindow()?.rootViewController as? NavigationController
    }

    static func getWindow() -> UIWindow? {
        let window = UIApplication.shared.windows
            .filter { ($0.rootViewController as? NavigationController) != nil }
            .first

        window?.makeKeyAndVisible()
        return window
    }
}

// MARK: - Handle Deeplink
extension Navigator {
    static func handleDeeplink(url: URL) {
        guard let scheme = url.scheme, scheme == Constant.appURLScheme,
            let host = url.host, let deeplinkHost = DeeplinkHost(rawValue: host)
            else {
                return
        }

        switch deeplinkHost {
        case .login:
            _ = AccountService.rxExistsCurrentAccount()
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { (account) in
                    guard account == nil else {
                        Navigator.default.show(segue: .launching, sender: nil, transition: .replace(type: .none))
                        return
                    }

                    guard let phrases = url.queryValue(for: "phrases")?.split(separator: "-").map(String.init), phrases.count == 12
                        else {
                            ErrorAlert.showErrorAlert(message: R.string.error.errorDeeplink())
                            return
                    }

                    _ = AccountService.rxGetAccount(phrases: phrases)
                        .observeOn(MainScheduler.instance)
                        .flatMapCompletable({ (account) -> Completable in
                            Global.current.account = account
                            return Global.current.setupCoreData()
                        })
                        .subscribe(onCompleted: {
                            Global.log.info("[done] execute lauching from deeplink")
                            Navigator.default.show(segue: .launching, sender: nil, transition: .replace(type: .none))
                        }, onError: { (error) in
                            errorWhenSignInAccount(error: error)
                        })
                }, onError: { (error) in
                    Global.log.error(error)
                    ErrorAlert.showErrorAlertWithSupport(message: R.string.error.system())
                })
        }
    }

    static func errorWhenSignInAccount(error: Error) {
        guard !AppError.errorByNetworkConnection(error) else { return }

        if type(of: error) == RecoverPhrase.RecoverPhraseError.self {
            ErrorAlert.showErrorAlert(message: R.string.error.errorDeeplink())
            return
        }

        Global.log.error(error)
        ErrorAlert.showErrorAlertWithSupport(message: R.string.error.system())
    }
}

enum ButtonItemType {
    case `continue`
    case back
    case none
}
