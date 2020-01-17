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

protocol Navigatable {
    var navigator: Navigator! { get set }
}

class Navigator {
    static var `default` = Navigator()

    // MARK: - segues list, all app scenes
    enum Scene {
        case launchingNavigation(viewModel: LaunchingViewModel)
        case launching(viewModel: LaunchingViewModel)
        case signInWall(viewModel: SignInWallViewModel)
        case signIn(viewModel: SignInViewModel)
        case howItWorks
        case trustIsCritical
        case askNotifications(viewModel: AskNotificationsViewModel)
        case getYourData(viewModel: GetYourDataViewModel)
        case requestData(viewModel: RequestDataViewModel)
        case dataRequested(viewModel: DataRequestedViewModel)
        case dataAnalyzing(viewModel: DataAnalyzingViewModel)
        case safari(URL)
        case safariController(URL)
        case hometabs
        case postList(viewModel: PostListViewModel)
        case reactionList(viewModel: ReactionListViewModel)
        case account(viewModel: AccountViewModel)
        case signOutWarning
        case signOut(viewModel: SignOutViewModel)
        case biometricAuth
        case viewRecoveryKeyWarning
        case viewRecoverykey(viewModel: ViewRecoveryKeyViewModel)
        case howFBTrack
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
        case .launchingNavigation(let viewModel):
            guard let launchVC = get(segue: .launching(viewModel: viewModel)) else { return NavigationController() }
            return NavigationController(rootViewController: launchVC)
        case .launching(let viewModel): return LaunchingViewController(viewModel: viewModel)
        case .signInWall(let viewModel): return SignInWallViewController(viewModel: viewModel)
        case .signIn(let viewModel): return SignInViewController(viewModel: viewModel)
        case .howItWorks: return HowItWorksViewController()
        case .trustIsCritical: return TrustIsCriticalViewController()
        case .askNotifications(let viewModel): return AskNotificationsViewController(viewModel: viewModel)
        case .getYourData(let viewModel): return GetYourDataViewController(viewModel: viewModel)
        case .requestData(let viewModel): return RequestDataViewController(viewModel: viewModel)
        case .dataRequested(let viewModel): return DataRequestedViewController(viewModel: viewModel)
        case .dataAnalyzing(let viewModel): return DataAnalyzingViewController(viewModel: viewModel)
        case .safari(let url):
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return nil

        case .safariController(let url):
            let vc = SFSafariViewController(url: url)
            return vc

        case .hometabs:
            return HomeTabbarController.tabbarController()
        case .postList(let viewModel): return PostListViewController(viewModel: viewModel)
        case .reactionList(let viewModel): return ReactionListViewController(viewModel: viewModel)
        case .account(let viewModel):
            let accountViewController = AccountViewController(viewModel: viewModel)
            accountViewController.hidesBottomBarWhenPushed = true
            return accountViewController

        case .signOutWarning: return SignOutWarningViewController()
        case .signOut(let viewModel): return SignOutViewController(viewModel: viewModel)
        case .biometricAuth: return BiometricAuthViewController()
        case .viewRecoveryKeyWarning: return ViewRecoveryKeyWarningViewController()
        case .viewRecoverykey(let viewModel): return ViewRecoveryKeyViewController(viewModel: viewModel)
        case .increasePrivacyList: return IncreasePrivacyListViewController()
        case .howFBTrack: return HowFBTrackViewController()
        case .increasePrivacy(let viewModel): return IncreasePrivacyViewController(viewModel: viewModel)
        case .about: return AboutViewController()
        case .faq: return FAQViewController()
        case .releaseNote(let buttonItemType):
            let releaseNoteViewController = ReleaseNoteViewController()
            releaseNoteViewController.buttonItemType = buttonItemType
            return releaseNoteViewController
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
                guard let currentVC = rootViewController.viewControllers.last,
                    [DataRequestedViewController.self, DataAnalyzingViewController.self].contains(where: { $0 == type(of: currentVC) })
                    else {
                        return
                }

                let viewModel = LaunchingViewModel()
                Navigator.default.show(segue: .launchingNavigation(viewModel: viewModel), sender: nil, transition: .root(in: window))
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
    static func evaluatePolicyWhenUserSetEnable() {
        guard Global.current.account != nil,
            let enteredBackgroundTime = UserDefaults.standard.enteredBackgroundTime else {
                return
        }
        guard Global.current.userDefault?.isAccountSecured ?? false else { return }
        guard Date() >= enteredBackgroundTime.adding(.minute, value: requireAuthorizationTime) else { return }

        retryAuthenticationAlert?.dismiss(animated: false, completion: nil)

        _ = AccountService.rx.existsCurrentAccount()
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { (_) in
                Navigator.retryAuthenticationAlert = ErrorAlert.showAuthenticationRequiredAlert {
                    Navigator.evaluatePolicyWhenUserSetEnable()
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

enum ButtonItemType {
    case `continue`
    case back
}