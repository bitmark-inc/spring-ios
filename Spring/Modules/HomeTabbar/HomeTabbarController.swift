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
import SnapKit

class HomeTabbarController: ESTabBarController, RequestDataDelegate {
    class func tabbarController(missions: [Mission]) -> HomeTabbarController {
        let insightsVC = InsightViewController(viewModel: InsightViewModel())
        let insightsNavVC = NavigationController(rootViewController: insightsVC)
        insightsNavVC.tabBarItem = ESTabBarItem(
            MainTabbarItemContentView(highlightColor: UIColor(hexString: "#0011AF")!),
            title: R.string.localizable.insights().localizedUppercase,
            image: R.image.insights_tab_icon(),
            tag: 0
        )

        let usageVC = UsageViewController(viewModel: UsageViewModel())
        let usageNavVC = NavigationController(rootViewController: usageVC)
        usageNavVC.tabBarItem = ESTabBarItem(
            MainTabbarItemContentView(highlightColor: UIColor(hexString: "#932C19")!),
            title: R.string.localizable.usage().localizedUppercase,
            image: R.image.usage_tab_icon(),
            tag: 1)

        let settingsVC = AccountViewController(viewModel: AccountViewModel())
        let settingsNavVC = NavigationController(rootViewController: settingsVC)
        settingsNavVC.tabBarItem = ESTabBarItem(
            MainTabbarItemContentView(highlightColor: UIColor(hexString: "#5F6D07")!),
            title: R.string.localizable.settings().localizedUppercase,
            image: R.image.account_icon(),
            tag: 2
        )

        let tabbarController = HomeTabbarController()
        tabbarController.missions = missions
        tabbarController.undoneMissions = missions
        tabbarController.viewControllers = [insightsNavVC, usageNavVC, settingsNavVC]

        return tabbarController
    }

    lazy var archiveStatusBox = makeArchiveStatusBox()
    lazy var appArchiveStatus = AppArchiveStatus.currentState

    // MARK: - Request Data Properties
    lazy var requestDataView = makeRequestDataView()
    lazy var guideTextLabel = makeGuideTextLabel()
    lazy var webView = makeWebView()
    let requestDataViewTop: CGFloat = 80
    var bottomRequestDataViewConstraint: Constraint?

    var missions = [Mission]() {
        didSet {
            if missions.count > 0 {
                view.insertSubview(requestDataView, aboveSubview: tabBar)

                requestDataView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview()
                    make.width.equalToSuperview()
                    make.height.equalToSuperview().offset(-requestDataViewTop)
                    bottomRequestDataViewConstraint = make.top.equalToSuperview().offset(view.height + 200).constraint
                }

                if missions.contains(.getCategories) {
                    getCategoriesState.accept(.loading)
                }

                if missions.contains(.downloadData) {
                    downloadFBArchiveState.accept(.hide)
                    observeWhenStillWaitingToDownloadArchive()
                }

                observeAndAskNotificationIfNeeded()
                observeEvents()
            }
        }
    }
    var undoneMissions = [Mission]()
    var fbScripts = [FBScript]()
    var cachedRequestHeader: [String : String]?
    lazy var archivePageScript = fbScripts.find(.archive)

    let guideStateRelay = BehaviorRelay<GuideState>(value: .start)
    let signUpAndSubmitArchiveResultSubject = PublishSubject<Event<Never>>()

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.isTranslucent = false

        themeService.rx
            .bind({ $0.background }, to: view.rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    fileprivate func observeAndAskNotificationIfNeeded() {
        BehaviorRelay
            .merge(requestFBArchiveState.asObservable(), downloadFBArchiveState.asObservable())
            .subscribe(onNext: { [weak self] (state) in
                guard let self = self, state == .success else { return }
                self.askNotification()
            })
            .disposed(by: disposeBag)
    }

    fileprivate func askNotification() {
        NotificationPermission.askForNotificationPermission(handleWhenDenied: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (authorizationStatus) in
                guard let self = self, authorizationStatus == .authorized else { return }

                self.scheduleReminderNotificationIfNeeded()
                self.registerOneSignal()
            })
            .disposed(by: disposeBag)
    }

    fileprivate func observeWhenStillWaitingToDownloadArchive() {
        archiveStatusBox.removeFromSuperview()
        view.insertSubview(archiveStatusBox, belowSubview: tabBar)

        archiveStatusBox.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-tabBar.height)
        }

        downloadFBArchiveState
            .subscribe(onNext: { [weak self] (state) in
                guard let self = self, state == .failed else { return }
                self.archiveStatusBox.up()
            })
            .disposed(by: disposeBag)
    }

    fileprivate func makeArchiveStatusBox() -> ArchiveStatusBox {
        return ArchiveStatusBox()
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
