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
            tag: 1)

        let settingsVC = AccountViewController(viewModel: AccountViewModel())
        let settingsNavVC = NavigationController(rootViewController: settingsVC)
        settingsNavVC.tabBarItem = ESTabBarItem(
            MainTabbarItemContentView(highlightColor: UIColor(hexString: "#5F6D07")!),
            title: R.string.localizable.settings().localizedUppercase,
            image: R.image.account_icon(),
            tag: 2)

        let tabbarController = HomeTabbarController()
        tabbarController.viewControllers = [usageNavVC, insightsNavVC, settingsNavVC]
        tabbarController.selectedIndex = 0

        return tabbarController
    }

    // MARK: - Request Data Properties
    lazy var automateRequestDataView = makeAutomateRequestDataView()
    let requestDataViewTop: CGFloat = 80
    var bottomRequestDataViewConstraint: Constraint?

    var missions = [Mission]() {
        didSet {
            if GetYourData.standard.optionRelay.value == .automate && InsightDataEngine.noExistsAdsCategories()  {
                missions.prepend(.getCategories)
                GetYourData.standard.getCategoriesState.accept(.loading)
            }

            undoneMissions = missions
            if missions.count > 0 {
                startAutomatingFbScripts()
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

        bindViewModel()
    }

    // 1. polling archive status when archive status is still processing
    // 2. observe the result of archive uploading
    // 3. observe the result of archive processing, show error if invalid
    fileprivate func bindViewModel() {
         // 1
        Global.pollingSyncAppArchiveStatus()

        // 2
        BackgroundTaskManager.shared.uploadProgressRelay
            .map { $0[SessionIdentifier.upload.rawValue] }.filterNil()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .error(let error):
                    self.handleErrorWhenUpload(error: error)
                case .completed:
                    Global.current.userDefault?.latestAppArchiveStatus = .processing
                    AppArchiveStatus.currentState.accept(.processing)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        Global.pollingSyncAppArchiveStatus()
                    }
                default:
                    break
                }
            })
            .disposed(by: disposeBag)

        // 3
        AppArchiveStatus.currentState
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (appArchiveStatus) in
                guard let self = self else { return }
                switch appArchiveStatus {
                case .invalid(let invalidArchiveIDs, let messageError):
                    guard let latestInvalidArchiveID = invalidArchiveIDs.first,
                        !UserDefaults.standard.showedInvalidArchiveIDs.contains(latestInvalidArchiveID)
                        else {
                            return
                    }

                    UserDefaults.standard.showedInvalidArchiveIDs = invalidArchiveIDs
                    self.handleErrorWhenArchiveInvalid(messageError: messageError)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] (settings) in
            guard let self = self else { return }
            if settings.authorizationStatus == .provisional || settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    self.registerOneSignal()
                }
            }
        }
    }
}

// MARK: - Handle Error
extension HomeTabbarController {
    fileprivate func handleErrorWhenArchiveInvalid(messageError: ArchiveMessageError?) {
        var errorTitle = R.string.error.generalTitle()
        var errorMessage = R.string.error.system()
        switch messageError {
        case .failToCreateArchive, .failToDownloadArchive:
            errorTitle = R.string.error.invalidArchiveFileTitle()
            errorMessage = R.string.error.invalidArchiveFileMessage()
        default:
            break
        }

        let alertController = ErrorAlert.invalidArchiveFileAlert(
            title: errorTitle,
            message: errorMessage) { [weak self] in
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

    fileprivate func handleErrorWhenUpload(error: Error) {
        Global.log.error(error)
        let alertController = ErrorAlert.invalidArchiveFileAlert(
            title: R.string.error.generalTitle(),
            message: R.string.error.system()) { [weak self] in
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

// MARK: - Automate Request FB Archive  Data
extension HomeTabbarController: RequestDataDelegate {
    func startAutomatingFbScripts() {
        automateRequestDataView.removeFromSuperview()
        view.insertSubview(automateRequestDataView, aboveSubview: tabBar)

        automateRequestDataView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview().offset(-requestDataViewTop)
            bottomRequestDataViewConstraint = make.top.equalToSuperview().offset(view.height + 200).constraint
        }

        automateRequestDataView.closeButton.rx.tap.bind { [weak self] in
            self?.closeAutomateRequestData()
        }.disposed(by: disposeBag)

        startAndObserveEvents()
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
