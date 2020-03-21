//
//  InsightViewController.swift
//  Spring
//
//  Created by Anh Nguyen on 11/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import BitmarkSDK
import RxSwift
import RxCocoa
import RxRealm
import FlexLayout
import RealmSwift
import Realm
import SwiftDate
import RxAppState

class InsightViewController: ViewController {

    lazy var thisViewModel = viewModel as! InsightViewModel

    // MARK: - Properties
    fileprivate lazy var scroll = UIScrollView()
    fileprivate lazy var insightView = UIView()
    fileprivate lazy var headingView = makeHeadingView()
    fileprivate lazy var automateRequestInfoView = makeAutomateRequestInfoView()
    fileprivate lazy var moreInsightsComingView = makeMoreInsightsComingView()
    fileprivate lazy var uploadProgressView = makeUploadProgressView()
    fileprivate lazy var requestUploadDataView = makeRequestUploadDataView()
    fileprivate lazy var browsePostsView = makeBrowseView(section: .browsePosts)
    fileprivate lazy var browsePhotosAndVideosView = makeBrowseView(section: .browsePhotosAndVideos)
    fileprivate lazy var browseLikesAndReactionsView = makeBrowseView(section: .browseLikesAndReactions)
    fileprivate lazy var dependentSections = UIView()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        uploadProgressView.restartIndeterminateProgressBar()
    }

    override func bindViewModel() {
        super.bindViewModel()

        UIApplication.shared.rx.didOpenApp
            .subscribe(onNext: { [weak uploadProgressView] (_) in
                uploadProgressView?.restartIndeterminateProgressBar()
            })
            .disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.contentSize = insightView.frame.size
    }

    override func setupViews() {
        super.setupViews()
        themeForContentView()

        insightView.flex.define { (flex) in
            flex.addItem(headingView)
            flex.addItem(dependentSections)
        }

        scroll.addSubview(insightView)
        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem(scroll).height(100%)
        }

        observeArchiveStatusToBuildInsights()
    }

    func observeArchiveStatusToBuildInsights() {
        BehaviorRelay.combineLatest(
            GetYourData.standard.optionRelay.distinctUntilChanged(),
            AppArchiveStatus.currentState.mapHighestStatus().distinctUntilChanged()
        )
        .subscribe(onNext: { [weak self] (getYourDataOption, currentState) in
            guard let self = self else { return }
            Global.log.debug("[renew insight]: with \(currentState)")

            self.dependentSections.removeSubviews()

            switch currentState {
            case .none, .invalid, .created: self.makeUIWhenNone(option: getYourDataOption)
            case .requesting:               self.makeUIWhenNone(option: getYourDataOption)
            case .uploading, .processing:   self.makeUIWhenProcessing(option: getYourDataOption)
            case .processed:                self.makeUIWhenProcessed(option: getYourDataOption)
            }

            self.dependentSections.flex.markDirty()
            self.layout()
        })
        .disposed(by: disposeBag)
    }

    // .none, .invalid, .created
    fileprivate func makeUIWhenNone(option: GetYourDataOption) {
        switch option {
        case .undefined, .manual:
            dependentSections.flex.addItem(SectionSeparator())
            dependentSections.flex.addItem(requestUploadDataView)
            requestUploadDataView.actionTitle = R.string.localizable.getStarted()
            dependentSections.flex.addItem(SectionSeparator())

        case .automate:
            dependentSections.flex.addItem(automateRequestInfoView)
        }
    }

    // .uploading, .processing
    fileprivate func makeUIWhenProcessing(option: GetYourDataOption) {
        switch option {
        case .undefined:
            Global.log.error("incorrect flow: option is undefined when processing")
            dependentSections.flex.addItem()

        case .automate, .manual:
            dependentSections.flex.addItem(uploadProgressView).marginTop(-22)
            dependentSections.flex.addItem(moreInsightsComingView).marginTop(-22)
        }
    }

    fileprivate func makeUIWhenProcessed(option: GetYourDataOption) {
        dependentSections.flex.addItem(SingleSeparator())
        dependentSections.flex.addItem(browsePostsView)
        dependentSections.flex.addItem(SingleSeparator())
        dependentSections.flex.addItem(browsePhotosAndVideosView)
        dependentSections.flex.addItem(SingleSeparator())
        dependentSections.flex.addItem(browseLikesAndReactionsView)
        dependentSections.flex.addItem(SingleSeparator())
    }
}

// MARK: - ContainerLayoutDelegate
extension InsightViewController: ContainerLayoutDelegate {
    func layout() {
        insightView.flex.markDirty()
        insightView.flex.layout(mode: .adjustHeight)
        scroll.contentSize = insightView.frame.size
    }
}

// MARK: - Navigator
extension InsightViewController {
    fileprivate func goToPostListScreen(filterScope: FilterScope) {
        let viewModel = PostListViewModel(filterScope: filterScope)
        navigator.show(segue: .postList(viewModel: viewModel), sender: self)
    }

    func gotoIncomeQuestionURL() {
        navigator.show(segue: .incomeQuestion, sender: self)
    }

    func gotoUploadDataScreen() {
        let viewModel = UploadDataViewModel()
        navigator.show(segue: .uploadData(viewModel: viewModel), sender: self)
    }

    func gotoPostListSectionScreen() {
        let viewModel = PostListSectionViewModel()
        navigator.show(segue: .postListSection(viewModel: viewModel), sender: self)
    }

    func gotoMediaListSectionScreen() {
        let viewModel = MediaListSectionViewModel()
        navigator.show(segue: .mediaListSection(viewModel: viewModel), sender: self)
    }

    func gotoReactionListSectionScreen() {
        let viewModel = ReactionListSectionViewModel()
        navigator.show(segue: .reactionListSection(viewModel: viewModel), sender: self)
    }
}

// MARK: - Setup Views
extension InsightViewController {
    fileprivate func makeHeadingView() -> HeadingView {
        let headingView = HeadingView()
        headingView.setHeading(
            title: R.string.localizable.browse().localizedUppercase,
            color:  ColorTheme.internationalKleinBlue.color)
        return headingView
    }

    fileprivate func makeSectionHeadingView(section: Section) -> SectionHeadingView {
        let sectionHeadingView = SectionHeadingView()
        sectionHeadingView.setProperties(section: section)
        return sectionHeadingView
    }

    fileprivate func makeMoreInsightsComingView() -> MoreComingView {
        let moreComingView = MoreComingView()
        moreComingView.containerLayoutDelegate = self
        return moreComingView
    }

    fileprivate func makeRequestUploadDataView() -> RequestUploadDataView {
        let requestUploadDataView = RequestUploadDataView()
        requestUploadDataView.containerLayoutDelegate = self
        requestUploadDataView.setProperties(section: .requestUploadDataInInsights, container: self)
        return requestUploadDataView
    }

    fileprivate func makeBrowseView(section: Section) -> BrowseView {
        let browseView = BrowseView()
        browseView.setProperties(section: section)

        browseView.selectButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            switch section {
            case .browsePosts:              self.gotoPostListSectionScreen()
            case .browsePhotosAndVideos:    self.gotoMediaListSectionScreen()
            case .browseLikesAndReactions:  self.gotoReactionListSectionScreen()
            default:
                break
            }
        }.disposed(by: disposeBag)

        return browseView
    }

    fileprivate func makeComingSoonLabel() -> Label {
        let label = Label()
        label.apply(
            text: R.string.localizable.comingSoon(),
            font: R.font.atlasGroteskLight(size: 22),
            colorTheme: .black)
        return label
    }

    fileprivate func makeUploadProgressView() -> ProgressView {
        let progressView = ProgressView()
        progressView.bindInfoInDashboard()
        return progressView
    }

    fileprivate func makeAutomateRequestInfoView() -> AutomateRequestInfoView {
        let infoView = AutomateRequestInfoView()
        return infoView
    }
}
