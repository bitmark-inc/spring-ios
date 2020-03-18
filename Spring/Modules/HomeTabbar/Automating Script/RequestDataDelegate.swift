//
//  RequestDataDelegate.swift
//  Spring
//
//  Created by Thuyen Truong on 2/27/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import FlexLayout
import WebKit
import RxSwift
import RxCocoa
import RxSwiftExt
import SnapKit

enum Mission {
    case requestData
    case checkRequestedData
    case downloadData
    case getCategories
}

enum GuideState {
    case start
    case automate
    case loginRequired
    case helpRequired
}

protocol RequestDataDelegate: WKNavigationDelegate {

    var disposeBag: DisposeBag { get }

    // MARK: - Properties
    var automateRequestDataView: AutomateRequestDataView { get set }
    var requestDataViewTop: CGFloat { get }
    var bottomRequestDataViewConstraint: Constraint? { get set }

    var missions: [Mission] { get set }
    var undoneMissions: [Mission] { get set }
    var fbScripts: [FBScript] { get set }
    var cachedRequestHeader: [String: String]? { get set }
    var archivePageScript: FBScript? { get set }

    // MARK: - Events
    var guideStateRelay: BehaviorRelay<GuideState> { get }
    var signUpAndSubmitArchiveResultSubject: PublishSubject<Event<Never>> { get }

    // MARK: - Handlers
    func startAndObserveEvents()
    func signUpAndSubmitFBArchive(headers: [String: String], archiveURL: URL, rawCookie: String)
    func signUpAndStoreAdsCategoriesInfo(_ adsCategories: [String]) -> Completable
    func closeAutomateRequestData()

    // Make UI
    func makeAutomateRequestDataView() -> AutomateRequestDataView
}

extension RequestDataDelegate where Self: UIViewController {
    var webView: WKWebView {
        return automateRequestDataView.webView
    }

    fileprivate func loadWebView() {
        guard let urlRequest = URLRequest(urlString: "https://m.facebook.com") else { return }
        webView.load(urlRequest)
    }

    fileprivate func finishMission() {
        undoneMissions.removeFirst()

        if !undoneMissions.isEmpty {
            loadWebView()
        } else {
            GetYourData.standard.runningState.accept(.success)
        }
    }

    // MARK: - Animation
    func slideUp() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.bottomRequestDataViewConstraint?.update(offset: self.requestDataViewTop)
            self.view.layoutIfNeeded()
        })
    }

    func slideDown(completionHandler: @escaping () -> Void = {}) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.bottomRequestDataViewConstraint?.update(offset: self.view.height + 200)
            self.view.layoutIfNeeded()
        }, completion: { _ in
            completionHandler()
        })
    }

    // MARK: - Observe Events
    func startAndObserveEvents() {
        signUpAndSubmitArchiveResultSubject
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .error(let error):
                    Global.log.error(error)

                case .completed:
                    Global.log.info("[done] SignUpAndSubmitArchive")
                    UserDefaults.standard.FBArchiveCreatedAt = nil

                    Global.pollingSyncAppArchiveStatus()

                    self.finishMission()
                default:
                    break
                }
            }).disposed(by: disposeBag)

        observeGuideState()

        GetYourData.standard.runningState.accept(.loading)
        ServerAssetsService.getFBAutomation()
            .subscribe(onSuccess: { [weak self] (fbScripts) in
                guard let self = self else { return }
                self.fbScripts = fbScripts
                self.loadWebView()
            }, onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: disposeBag)
    }

    func observeGuideState() {
        guideStateRelay
            .subscribe(onNext: { [weak self] (guideState) in
                guard let self = self else { return }
                switch guideState {
                case .start:
                    self.automateRequestDataView.backgroundColor = ColorTheme.cognac.color
                    self.automateRequestDataView.guideText = nil

                case .automate:
                    self.automateRequestDataView.backgroundColor = ColorTheme.cognac.color
                    self.automateRequestDataView.guideText = nil
                    self.slideDown()

                case .loginRequired:
                    self.automateRequestDataView.backgroundColor = ColorTheme.cognac.color
                    self.automateRequestDataView.guideText = R.string.phrase.guideRequiredLogin().localizedUppercase
                    self.slideUp()

                case .helpRequired:
                    self.automateRequestDataView.backgroundColor = ColorTheme.internationalKleinBlue.color
                    self.automateRequestDataView.guideText = R.string.phrase.guideRequiredHelp().localizedUppercase
                    self.slideUp()
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - EvaluateJS
    func evaluateJS(index: Int) {
        let numberOfScript = fbScripts.count
        let pageScript = fbScripts[index]

        automateRequestDataView.webView.evaluateJavaScript(pageScript.detection) { (result, error) in
            Global.log.info("[start] evaluateJS for \(pageScript.name): \(result ?? "")")
            if let error = error { Global.log.info("Error: \(error)") }

            guard error == nil, let result = result as? Bool, result else {
                let nextIndex = index + 1
                if nextIndex < numberOfScript {
                    self.evaluateJS(index: nextIndex)
                } else {
                    // is not the page in all detection pages, show required help
                    self.guideStateRelay.accept(.helpRequired)
                }

                return
            }

            guard let facePage = FBPage(rawValue: pageScript.name) else { return }

            switch facePage {
            case .login: self.guideStateRelay.accept(.loginRequired)
            case .reauth: self.guideStateRelay.accept(.helpRequired)
            case .archive: break
            case .demographics, .behaviors: break
            default:
                self.guideStateRelay.accept(.automate)
            }

            switch facePage {
            case .saveDevice:       self.runJS(saveDeviceScript: pageScript)
            case .newFeed:          self.runJS(newFeedScript: pageScript)
            case .settings:         self.runJS(settingsScript: pageScript)
            case .adsPreferences:   self.runJS(adsPreferencesScript: pageScript)
            case .accountPicking:   self.runJS(accountPickingScript: pageScript)
            default:
                break
            }
        }
    }

    fileprivate func checkIsPage(script: FBScript) -> Observable<Void> {
        return Observable<Void>.create { (event) -> Disposable in
            let detection = script.detection

            self.webView.evaluateJavaScript(detection) { (result, error) in
                guard error == nil, let isRequiredPage = result as? Bool, isRequiredPage else {
                    event.onError(AppError.fbRequiredPageIsNotReady)
                    return
                }
                event.onCompleted()
            }

            return Disposables.create()
        }
    }

    // MARK: saveDevice Script
    fileprivate func runJS(saveDeviceScript: FBScript) {
        guard let notNowAction = saveDeviceScript.script(for: .notNow) else { return }
        webView.evaluateJavaScript(notNowAction)
    }

    // MARK: newFeed Script
    fileprivate func runJS(newFeedScript: FBScript) {
        guard let gotoSettingsPageAction = newFeedScript.script(for: .goToSettingsPage) else { return }
        webView.evaluateJavaScript(gotoSettingsPageAction)
    }

    // MARK: Settings Script
    fileprivate func runJS(settingsScript: FBScript) {
        guard let doingMission = undoneMissions.first else { return }

        switch doingMission {
        case .requestData, .checkRequestedData, .downloadData:
            guard let goToArchivePageAction = settingsScript.script(for: .goToArchivePage) else { return }

            webView.evaluateJavaScript(goToArchivePageAction) { [weak self] (_, error) in
                guard let self = self else { return }
                guard error == nil else {
                    Global.log.error(error)
                    return
                }
                self.doMissionInArchivePage() // it's not trigger webView#didFinish function
            }
        case .getCategories:
            guard let goToAdsPreferencesPageAction = settingsScript.script(for: .goToAdsPreferencesPage) else { return }

            webView.evaluateJavaScript(goToAdsPreferencesPageAction) { [weak self] (_, error) in
                guard let self = self else { return }
                guard error == nil else {
                    Global.log.error(error)
                    return
                }

                self.doMissionInAdsPage() // it's not trigger webView#didFinish function
            }
        }
    }

    // MARK: - doMissionInArchivePage
    fileprivate func doMissionInArchivePage() {
        guard let archivePageScript = archivePageScript else { return }
        checkIsPage(script: archivePageScript)
            .retry(.delayed(maxCount: 1000, time: 0.5))
            .subscribe(onError: { [weak self] (error) in
                Global.log.error(error)
                self?.guideStateRelay.accept(.helpRequired)
            }, onCompleted: { [weak self] in
                guard let self = self else { return }
                Global.log.info("[start] evaluateJS for archive")

                if self.missions.contains(.requestData) {
                    self.runJSToCreateDataArchive()
                } else if self.missions.contains(.downloadData) {
                    self.runJSTodownloadFBArchiveIfExist()
                }

            })
            .disposed(by: disposeBag)
    }

    // MARK: - runJSToCreateDataArchive
    fileprivate func runJSToCreateDataArchive() {
        guard let archivePageScript = archivePageScript,
            let selectRequestTabAction = archivePageScript.script(for: .selectRequestTab),
            let selectJSONOptionAction = archivePageScript.script(for: .selectJSONOption),
            let selectHighResolutionOptionAction = archivePageScript.script(for: .selectHighResolutionOption),
            let createFileAction = archivePageScript.script(for: .createFile)
            else {
                return
        }

        let action = [selectRequestTabAction, selectJSONOptionAction, selectHighResolutionOptionAction, createFileAction].joined()

        webView.evaluateJavaScript(action) { [weak self] (_, error) in
            guard let self = self else { return }
            guard error == nil else {
                Global.log.error(error)
                return
            }

            Global.log.info("[done] createFBArchive")
            UserDefaults.standard.FBArchiveCreatedAt = Date()
            self.finishMission()
        }
    }

    // MARK: - runJSTodownloadFBArchiveIfExist
    fileprivate func runJSTodownloadFBArchiveIfExist() {
        guard let isCreatingFileAction = archivePageScript?.script(for: .isCreatingFile) else {
            return
        }

        webView.evaluateJavaScript(isCreatingFileAction) { [weak self] (result, error) in
            guard let self = self else { return }
            guard error == nil, let isCreatingFile = result as? Bool else {
                Global.log.error(error)
                return
            }

            if isCreatingFile {
                self.finishMission()
            } else {
                self.runJSTodownloadFBArchive()
            }
        }
    }

    // MARK: - runJSTodownloadFBArchive
    func runJSTodownloadFBArchive() {
        guard let archivePageScript = archivePageScript,
            let selectDownloadTabAction = archivePageScript.script(for: .selectDownloadTab),
            let selectJSONOptionAction = archivePageScript.script(for: .downloadFirstFile)
            else {
                return
        }

        let action = [selectDownloadTabAction, selectJSONOptionAction].joined()

        webView.evaluateJavaScript(action) { (_, error) in
            guard error == nil else {
                Global.log.error(error)
                return
            }
        }
    }

    // MARK: - doMissionInAdsPage
    fileprivate func doMissionInAdsPage() {
        guard let adsPageScript = fbScripts.find(.adsPreferences) else { return }
        checkIsPage(script: adsPageScript)
            .retry(.delayed(maxCount: 1000, time: 0.5))
            .subscribe(onError: { [weak self] (error) in
                Global.log.error(error)
                self?.guideStateRelay.accept(.helpRequired)
            }, onCompleted: { [weak self] in
                guard let self = self else { return }
                Global.log.info("[start] evaluateJS for adsPreferences")

                self.runJS(adsPreferencesScript: adsPageScript)
            })
            .disposed(by: disposeBag)
    }

    // MARK: AdsPreferences Script
    fileprivate func runJS(adsPreferencesScript: FBScript) {
        guard let goToYourInformationPageAction = adsPreferencesScript.script(for: .goToYourInformationPage)
            else {
                return
        }

        webView.evaluateJavaScript(goToYourInformationPageAction) { [weak self] (_, error) in
            guard let self = self else { return }
            guard error == nil else {
                Global.log.error(error)
                return
            }

            guard let demographicsPageScript = self.fbScripts.find(.demographics) else { return }
            self.runJS(demographicsScript: demographicsPageScript)
        }
    }

    // MARK: Demographics Script
    fileprivate func runJS(demographicsScript: FBScript) {
        checkIsPage(script: demographicsScript)
            .retry(.delayed(maxCount: 1000, time: 0.5))
            .subscribe(onError: { [weak self] (error) in
                Global.log.error(error)
                self?.guideStateRelay.accept(.helpRequired)
                }, onCompleted: { [weak self] in
                    guard let self = self else { return }
                    Global.log.info("[start] evaluateJS for demographics")

                    guard let goToBehaviorsPageAction = demographicsScript.script(for: .goToBehaviorsPage)
                        else {
                            return
                    }

                    self.webView.evaluateJavaScript(goToBehaviorsPageAction) { [weak self] (_, error) in
                        guard let self = self else { return }
                        guard error == nil else {
                            Global.log.error(error)
                            return
                        }

                        guard let behaviorsScript = self.fbScripts.find(.behaviors) else { return }
                        self.runJS(behaviorsScript: behaviorsScript)
                    }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Behaviors Script
    fileprivate func runJS(behaviorsScript: FBScript) {
        checkIsPage(script: behaviorsScript)
            .retry(.delayed(maxCount: 1000, time: 0.5))
            .subscribe(onError: { [weak self] (error) in
                Global.log.error(error)
                self?.guideStateRelay.accept(.helpRequired)
                }, onCompleted: { [weak self] in
                    guard let self = self else { return }
                    Global.log.info("[start] evaluateJS for behavior")

                    guard let getCategoriesAction = behaviorsScript.script(for: .getCategories)
                        else {
                            return
                    }

                    self.webView.evaluateJavaScript(getCategoriesAction) { [weak self] (adsCategories, error) in
                        guard error == nil else {
                            Global.log.error(error)
                            return
                        }

                        guard let self = self,
                            let adsCategories = adsCategories as? [String] else { return }

                        self.signUpAndStoreAdsCategoriesInfo(adsCategories)
                            .subscribe(onCompleted: { [weak self] in
                                GetYourData.standard.getCategoriesState.accept(.success)
                                self?.finishMission()
                            }, onError: { (error) in
                                Global.log.error(error)
                                GetYourData.standard.getCategoriesState.accept(.failed)
                            })
                            .disposed(by: self.disposeBag)
                    }
            })
            .disposed(by: disposeBag)
    }

    // MARK: Account Picking Script
    fileprivate func runJS(accountPickingScript: FBScript) {
        guard let pickAnotherAction = accountPickingScript.script(for: .pickAnother)
            else {
                return
        }

        webView.evaluateJavaScript(pickAnotherAction)
    }

    // MARK: - Handlers
    func signUpAndSubmitFBArchive(headers: [String: String], archiveURL: URL, rawCookie: String) {
        let fbArchiveCreatedAtTime: Date!
        if let fbArchiveCreatedAt = UserDefaults.standard.FBArchiveCreatedAt {
            fbArchiveCreatedAtTime = fbArchiveCreatedAt
        } else {
            fbArchiveCreatedAtTime = Date()
            Global.log.error(AppError.emptyFBArchiveCreatedAtInUserDefaults)
        }

        FBArchiveService.submit(
            headers: headers,
            fileURL: archiveURL.absoluteString,
            rawCookie: rawCookie,
            startedAt: nil,
            endedAt: fbArchiveCreatedAtTime)
        .asObservable()
        .materialize().bind { [weak self] in
            self?.signUpAndSubmitArchiveResultSubject.onNext($0)
        }
        .disposed(by: disposeBag)
    }

    func signUpAndStoreAdsCategoriesInfo(_ adsCategories: [String]) -> Completable {
        return Completable.deferred {
            do {
                let userInfo = try UserInfo(key: .adsCategory, value: adsCategories)
                return Storage.store(userInfo)
            } catch {
                return Completable.error(error)
            }
        }
    }

    func closeAutomateRequestData() {
        slideDown { [weak self] in
            guard let self = self else { return }
            self.automateRequestDataView.removeFromSuperview()

            GetYourData.standard.getCategoriesState.accept(.hide)
            GetYourData.standard.runningState.accept(.hide)
            GetYourData.standard.optionRelay.accept(.undefined)

            let viewModel = UploadDataViewModel()
            Navigator.default.show(segue: .uploadData(viewModel: viewModel), sender: self)
        }
    }

    // MARK: - Setup Views
    func makeAutomateRequestDataView() -> AutomateRequestDataView {
        let automateRequestDataView = AutomateRequestDataView()
        automateRequestDataView.webView.navigationDelegate = self

        switch AppArchiveStatus.currentState.value {
        case .processed: automateRequestDataView.closeButton.isHidden = true
        default:         automateRequestDataView.closeButton.isHidden = false
        }

        return automateRequestDataView
    }
}
