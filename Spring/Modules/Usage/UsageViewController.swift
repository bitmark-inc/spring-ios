//
//  UsageViewController.swift
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

protocol ContainerLayoutDelegate: class {
    func layout()
}

protocol TimelineDelegate: class {
    func updateTimeUnit(_ timeUnit: TimeUnit)
    func nextPeriod()
    func prevPeriod()
}

protocol NavigatorDelegate: class {
    func goToPostListScreen(filterBy: GroupKey, filterValue: Any)
    func goToReactionListScreen(filterBy: GroupKey, filterValue: Any)
}

class UsageViewController: ViewController {

    lazy var thisViewModel = viewModel as! UsageViewModel

    // MARK: - Properties
    lazy var scroll = UIScrollView()
    lazy var usageView = UIView()
    lazy var headingView = makeHeadingView()
    lazy var timelineView = makeTimelineView()
    lazy var postsHeadingView = makeSectionHeadingView(section: .post)
    lazy var postsFilterTypeView = makeFilterTypeView(section: .post)
    lazy var postsFilterDayView = makeFilterDayView(section: .post)
    lazy var postsFilterFriendView = makeFilterGeneralView(section: .post, groupBy: 
        .friend)
    lazy var postsFilterPlaceView = makeFilterGeneralView(section: .post, groupBy:
        .place)
    lazy var reationsHeadingView = makeSectionHeadingView(section: .reaction)
    lazy var reactionsFilterTypeView = makeFilterTypeView(section: .reaction)
    lazy var reactionsFilterDayView = makeFilterDayView(section: .reaction)
    lazy var reactionsFilterFriendView = makeFilterGeneralView(section: .reaction, groupBy:
        .friend)
    lazy var morePersonalAnalyticsComingView = makeMorePersonalAnalyticsComingView()
    lazy var requestUploadDataView = makeRequestUploadDataView()
    lazy var aggregateAnalysisView = makeAggregateAnalysisView()
    lazy var prefixDependentUsageSections = UIView()
    lazy var suffixDependentUsageSections = UIView()

    // SECTION: Mood
    lazy var moodObservable: Observable<Usage> = {
        thisViewModel.realmMoodRelay.filterNil()
            .flatMap { Observable.from(object: $0) }
    }()

    // SECTION: Post
    lazy var postUsageObservable: Observable<Usage> = {
        thisViewModel.realmPostUsageRelay.filterNil()
            .flatMap { Observable.from(object: $0) }
    }()

    lazy var groupsPostUsageObservable: Observable<Groups> = {
        postUsageObservable
            .map { $0.groups }
            .map { try Converter<Groups>(from: $0).value }
    }()

    // SECTION: Reaction
    lazy var reactionUsageObservable: Observable<Usage> = {
        thisViewModel.realmReactionUsageRelay.filterNil()
            .flatMap { Observable.from(object: $0) }
    }()

    lazy var groupsReactionUsageObservable: Observable<Groups> = {
        reactionUsageObservable
            .map { $0.groups }
            .map { try Converter<Groups>(from: $0).value }
    }()

    var segmentDistances: [TimeUnit: Int] = [
        .week: 0, .year: 0, .decade: 0
    ]

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func bindViewModel() {
        super.bindViewModel()
        
        guard let viewModel = viewModel as? UsageViewModel else { return }

        viewModel.fetchDataResultSubject
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .error(let error):
                    self.errorWhenFetchingData(error: error)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)

        viewModel.segmentDistances
            .subscribe(onNext: { [weak self] in
                self?.segmentDistances = $0
            })
            .disposed(by: disposeBag)

        viewModel.dateRelay
            .subscribe(onNext: { [weak self] (startDate) in
                guard let self = self else { return }

                let timeUnit = self.thisViewModel.timeUnitRelay.value
                let datePeriod = startDate.extractDatePeriod(timeUnit: timeUnit)

                let distance = self.segmentDistances[timeUnit]!
                let limitedDistance = viewModel.segmentDistances.value[timeUnit]!
                self.timelineView.bindData(
                    periodName: timeUnit.meaningTimeText(with: distance),
                    periodDescription: datePeriod.makeTimelinePeriodText(in: timeUnit),
                    distance: distance, limitedDistance: limitedDistance)
            })
            .disposed(by: disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let viewModel = viewModel as? UsageViewModel else { return }

        viewModel.fetchSpringStats()

        AppArchiveStatus.currentState
            .filter { $0?.rawValue == "processed" }
            .take(1).ignoreElements()
            .andThen(viewModel.fetchActivity())
            .subscribe(onCompleted: {
                viewModel.fetchUsage()
            }, onError: { [weak self] (error) in
                self?.errorWhenFetchingData(error: error)
            })
            .disposed(by: disposeBag)
    }

    func errorWhenFetchingData(error: Error) {
        guard !AppError.errorByNetworkConnection(error),
            !showIfRequireUpdateVersion(with: error),
            !handleErrorIfAsAFError(error) else {
                return
        }

        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.system())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.contentSize = usageView.frame.size
    }

    override func setupViews() {
        super.setupViews()
        themeForContentView()

        usageView.flex.define { (flex) in
            flex.addItem(headingView)
            flex.addItem(timelineView)
            flex.addItem(prefixDependentUsageSections)
            flex.addItem(SectionSeparator())
            flex.addItem(aggregateAnalysisView)
            flex.addItem(SectionSeparator())
            flex.addItem(suffixDependentUsageSections)
        }

        scroll.addSubview(usageView)
        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem(scroll).height(100%)
            }

        observeArchiveStatusToBuildUsage()
    }

    func observeArchiveStatusToBuildUsage() {
        AppArchiveStatus.currentState
            .filterNil()
            .distinctUntilChanged { $0.rawValue == $1.rawValue }
            .subscribe(onNext: { [weak self] (appArchiveStatus) in
                guard let self = self else { return }
                self.suffixDependentUsageSections.removeSubviews()
                self.prefixDependentUsageSections.removeSubviews()
                switch appArchiveStatus {
                case .none, .invalid, .created:
                    self.prefixDependentUsageSections.flex.addItem()
                    self.suffixDependentUsageSections.flex.addItem(self.requestUploadDataView)
                    self.suffixDependentUsageSections.flex.addItem(SectionSeparator())
                    self.requestUploadDataView.actionTitle = R.string.localizable.getStarted()

                case .uploading:
                    self.prefixDependentUsageSections.flex.addItem()
                    self.suffixDependentUsageSections.flex.addItem(self.requestUploadDataView)
                    self.suffixDependentUsageSections.flex.addItem(SectionSeparator())
                    self.requestUploadDataView.actionTitle = R.string.localizable.view_progress()

                case .processing:
                    self.prefixDependentUsageSections.flex.addItem(SectionSeparator())
                    self.prefixDependentUsageSections.flex.addItem(self.morePersonalAnalyticsComingView)
                    self.suffixDependentUsageSections.flex.addItem(self.requestUploadDataView)
                    self.suffixDependentUsageSections.flex.addItem(SectionSeparator())
                    self.requestUploadDataView.actionTitle = R.string.localizable.view_progress()

                case .processed:
                    self.prefixDependentUsageSections.flex.addItem()
                    self.suffixDependentUsageSections.flex.addItem(self.postsHeadingView)
                    self.suffixDependentUsageSections.flex.addItem(self.postsFilterTypeView)
                    self.suffixDependentUsageSections.flex.addItem(self.postsFilterDayView)
                    self.suffixDependentUsageSections.flex.addItem(self.postsFilterFriendView)
                    self.suffixDependentUsageSections.flex.addItem(self.postsFilterPlaceView)
                    self.suffixDependentUsageSections.flex.addItem(SectionSeparator())
                    self.suffixDependentUsageSections.flex.addItem(self.reationsHeadingView)
                    self.suffixDependentUsageSections.flex.addItem(self.reactionsFilterTypeView)
                    self.suffixDependentUsageSections.flex.addItem(self.reactionsFilterDayView)
                    self.suffixDependentUsageSections.flex.addItem(self.reactionsFilterFriendView)
                }

                self.prefixDependentUsageSections.flex.markDirty()
                self.suffixDependentUsageSections.flex.markDirty()
                self.layout()
            })
            .disposed(by: disposeBag)
    }
}

extension UsageViewController {
    fileprivate func makeHeadingView() -> HeadingView {
        let headingView = HeadingView()
        headingView.setHeading(title: R.string.localizable.summary().localizedUppercase, color:  UIColor(hexString: "#932C19"))
        return headingView
    }

    fileprivate func makeTimelineView() -> TimeFilterView {
        let timeFilterView = TimeFilterView()
        timeFilterView.timelineDelegate = self
        return timeFilterView
    }

    fileprivate func makeSectionHeadingView(section: Section) -> SectionHeadingView {
        let sectionHeadingView = SectionHeadingView()
        sectionHeadingView.setProperties(section: section, container: self)
        sectionHeadingView.flex.padding(0, 18, 26, 18)
        return sectionHeadingView
    }

    fileprivate func makeFilterTypeView(section: Section) -> FilterTypeView {
        let filterTypeView = FilterTypeView()
        filterTypeView.setProperties(section: section, container: self)
        filterTypeView.containerLayoutDelegate = self
        filterTypeView.navigatorDelegate = self
        filterTypeView.selectionEnabled = true
        return filterTypeView
    }

    fileprivate func makeFilterDayView(section: Section) -> FilterDayView {
        let filterDayView = FilterDayView()
        filterDayView.setProperties(section: section, container: self)
        filterDayView.containerLayoutDelegate = self
        filterDayView.navigatorDelegate = self
        return filterDayView
    }

    fileprivate func makeFilterGeneralView(section: Section, groupBy groupKey: GroupKey) -> FilterGeneralView {
        let filterGeneralView = FilterGeneralView()
        filterGeneralView.setProperties(section: section, groupKey: groupKey, container: self)
        filterGeneralView.containerLayoutDelegate = self
        filterGeneralView.navigatorDelegate = self
        return filterGeneralView
    }

    fileprivate func makeMorePersonalAnalyticsComingView() -> MoreComingView {
        let moreComingView = MoreComingView()
        moreComingView.containerLayoutDelegate = self
        moreComingView.section = .morePersonalAnalyticsComing
        return moreComingView
    }

    fileprivate func makeAggregateAnalysisView() -> AggregateAnalysisView {
        let aggregateAnalysisView = AggregateAnalysisView()
        aggregateAnalysisView.containerLayoutDelegate = self
        aggregateAnalysisView.setProperties(container: self)
        return aggregateAnalysisView
    }

    fileprivate func makeRequestUploadDataView() -> RequestUploadDataView {
        let requestUploadDataView = RequestUploadDataView()
        requestUploadDataView.containerLayoutDelegate = self
        requestUploadDataView.setProperties(section: .requestUploadDataInUsage, container: self)
        return requestUploadDataView
    }
}

// MARK: - ContainerLayoutDelegate
extension UsageViewController: ContainerLayoutDelegate {
    func layout() {
        usageView.flex.markDirty()
        usageView.flex.layout(mode: .adjustHeight)
        scroll.contentSize = usageView.frame.size
    }
}

// MARK: - TimelineDelegate
extension UsageViewController: TimelineDelegate {
    func updateTimeUnit(_ timeUnit: TimeUnit) {
        let distance = segmentDistances[timeUnit]!
        let updatedDate = Date().dateAtStartOfTimeUnit(timeUnit: timeUnit, distance: distance)

        thisViewModel.timeUnitRelay.accept(timeUnit)
        thisViewModel.dateRelay.accept(updatedDate)
    }

    func nextPeriod() {
        let currentDate = thisViewModel.dateRelay.value
        let nextDate: Date!

        switch thisViewModel.timeUnitRelay.value {
        case .week: nextDate = currentDate + 1.weeks
        case .year: nextDate = currentDate + 1.years
        case .decade: nextDate = currentDate + 10.years
        }

        let timeUnit = thisViewModel.timeUnitRelay.value
        segmentDistances[timeUnit]! += 1
        thisViewModel.dateRelay.accept(nextDate)
    }

    func prevPeriod() {
        let currentDate = thisViewModel.dateRelay.value
        let prevDate: Date!

        switch thisViewModel.timeUnitRelay.value {
        case .week: prevDate = currentDate - 1.weeks
        case .year: prevDate = currentDate - 1.years
        case .decade: prevDate = currentDate - 10.years
        }

        let timeUnit = thisViewModel.timeUnitRelay.value
        segmentDistances[timeUnit]! -= 1
        thisViewModel.dateRelay.accept(prevDate)
    }
}

// MARK: - NavigatorDelegate
extension UsageViewController: NavigatorDelegate {
    func goToPostListScreen(filterBy: GroupKey, filterValue: Any) {
        let filterScope = FilterScope(
            date: thisViewModel.dateRelay.value,
            timeUnit: thisViewModel.timeUnitRelay.value,
            section: .post,
            filterBy: filterBy, filterValue: filterValue)

        let viewModel = PostListViewModel(filterScope: filterScope)
        navigator.show(segue: .postList(viewModel: viewModel), sender: self)
    }

    func goToReactionListScreen(filterBy: GroupKey, filterValue: Any) {
        let filterScope = FilterScope(
            date: thisViewModel.dateRelay.value,
            timeUnit: thisViewModel.timeUnitRelay.value,
            section: .reaction,
            filterBy: filterBy, filterValue: filterValue)

        let viewModel = ReactionListViewModel(filterScope: filterScope)
        navigator.show(segue: .reactionList(viewModel: viewModel), sender: self)
    }

    func gotoUploadDataScreen() {
        let viewModel = UploadDataViewModel()
        navigator.show(segue: .uploadData(viewModel: viewModel), sender: self)
    }
}
