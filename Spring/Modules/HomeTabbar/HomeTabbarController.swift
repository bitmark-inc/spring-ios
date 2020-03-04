//
//  HomeTabbarController.swift
//  Spring
//
//  Created by Anh Nguyen on 11/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import ESTabBarController_swift
import RxSwift
import RxCocoa

class HomeTabbarController: ESTabBarController {
    class func tabbarController() -> HomeTabbarController {
        let usageVC = UsageViewController(viewModel: UsageViewModel())
        let usageNavVC = NavigationController(rootViewController: usageVC)
        usageNavVC.tabBarItem = ESTabBarItem(
            MainTabbarItemContentView(highlightColor: UIColor(hexString: "#932C19")!),
            title: R.string.localizable.summary().localizedUppercase,
            image: R.image.usage_tab_icon(),
            tag: 0)

        let insightsVC = InsightViewController(viewModel: InsightViewModel())
        let insightsNavVC = NavigationController(rootViewController: insightsVC)
        insightsNavVC.tabBarItem = ESTabBarItem(
            MainTabbarItemContentView(highlightColor: UIColor(hexString: "#0011AF")!),
            title: R.string.localizable.browse().localizedUppercase,
            image: R.image.browseTabIcon(),
            tag: 1
        )

        let settingsVC = AccountViewController(viewModel: AccountViewModel())
        let settingsNavVC = NavigationController(rootViewController: settingsVC)
        settingsNavVC.tabBarItem = ESTabBarItem(
            MainTabbarItemContentView(highlightColor: UIColor(hexString: "#5F6D07")!),
            title: R.string.localizable.settings().localizedUppercase,
            image: R.image.account_icon(),
            tag: 2
        )

        let tabbarController = HomeTabbarController()
        tabbarController.viewControllers = [usageNavVC, insightsNavVC, settingsNavVC]
        tabbarController.selectedIndex = 0

        return tabbarController
    }

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.isTranslucent = false

        themeService.rx
            .bind({ $0.background }, to: view.rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        syncAppArchiveStatus()

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] (settings) in
            guard let self = self else { return }
            if settings.authorizationStatus == .provisional || settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    self.registerOneSignal()
                }
            }
        }

        // observe the result of archive uploading
        BackgroundTaskManager.shared.uploadProgressRelay
            .map { $0[SessionIdentifier.upload.rawValue] }.filterNil()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .error(let error):
                    self.handleErrorWhenUpload(error: error)
                case .completed:
                    self.syncAppArchiveStatus()
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    fileprivate func syncAppArchiveStatus() {
        ArchiveDataEngine.fetchAppArchiveStatus()
            .subscribe(onSuccess: {
                Global.current.userDefault?.latestAppArchiveStatus = $0
                AppArchiveStatus.currentState.accept($0)
            }, onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Handle Error
extension HomeTabbarController {
    fileprivate func handleErrorWhenUpload(error: Error) {
        var errorMessage = R.string.error.system()
        if let error = error as? ServerAPIError {
            switch error.code {
            case .InvalidArchiveFile:
                errorMessage = R.string.error.invalidArchiveFile()
            default:
                break
            }
        }

        Global.log.error(error)
        let alertController = ErrorAlert.invalidArchiveFileAlert(message: errorMessage) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self, let selectedNavigation = self.selectedViewController as? NavigationController,
                    let sender = selectedNavigation.topViewController,
                    !(sender is UploadDataViewController) else { return }

                let viewModel = UploadDataViewModel()
                Navigator.default.show(segue: .uploadData(viewModel: viewModel), sender: sender)
            }

        }
        alertController.show()
    }
}

class MainTabbarItemContentView: ESTabBarItemContentView {
    let disposeBag = DisposeBag()
    let selectedIndicatorLineView = UIView()

    convenience init(highlightColor: UIColor) {
        self.init()
        
        selectedIndicatorLineView.backgroundColor = highlightColor
        highlightIconColor = highlightColor
        highlightTextColor = highlightColor
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Add view
        addSubview(selectedIndicatorLineView)

        themeService.rx
            .bind({ $0.blackTextColor }, to: rx.textColor)
            .bind({ $0.blackTextColor }, to: rx.iconColor)
            .bind({ $0.textViewBackgroundColor }, to: rx.backdropColor)
            .bind({ $0.textViewBackgroundColor }, to: rx.highlightBackdropColor)
        .disposed(by: disposeBag)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateDisplay() {
        super.updateDisplay()

        selectedIndicatorLineView.isHidden = !selected
    }

    override func updateLayout() {
        super.updateLayout()

        selectedIndicatorLineView.frame = CGRect(x: 0, y: -1, width: self.bounds.size.width, height: 2)
    }
}

extension Reactive where Base: ESTabBarItemContentView {

    var textColor: Binder<UIColor> {
        return Binder(self.base) { view, attr in
            view.textColor = attr
        }
    }

    var highlightTextColor: Binder<UIColor> {
        return Binder(self.base) { view, attr in
            view.highlightTextColor = attr
        }
    }

    var iconColor: Binder<UIColor> {
        return Binder(self.base) { view, attr in
            view.iconColor = attr
        }
    }

    var highlightIconColor: Binder<UIColor> {
        return Binder(self.base) { view, attr in
            view.highlightIconColor = attr
        }
    }

    var backdropColor: Binder<UIColor> {
        return Binder(self.base) { view, attr in
            view.backdropColor = attr
        }
    }

    var highlightBackdropColor: Binder<UIColor> {
        return Binder(self.base) { view, attr in
            view.highlightBackdropColor = attr
        }
    }
}
