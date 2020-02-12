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

class InsightViewController: ViewController {

    lazy var thisViewModel = viewModel as! InsightViewModel

    // MARK: - Properties
    lazy var scroll = UIScrollView()
    lazy var insightView = UIView()
    lazy var headingView = makeHeadingView()
    lazy var fbIncomeView = makeFBIncomeView()
    lazy var adsCategoryView = makeAdsCategoryView()
    lazy var moreInsightsComingView = makeMoreInsightsComingView()

    // SECTION: FB Income
    lazy var realmInsightObservable: Observable<Insight> = {
        thisViewModel.realmInsightsInfoRelay.filterNil()
            .flatMap { Observable.from(object: $0) }
            .map { $0.valueObject() }.filterNil()
    }()

    lazy var appArchiveStatus: AppArchiveStatus = AppArchiveStatus.currentState

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? InsightViewModel else { return }
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

        viewModel.fetchQuickInsight()

        if appArchiveStatus == .done {
            viewModel.fetchInsight()
        }
    }

    func errorWhenFetchingData(error: Error) {
        guard !AppError.errorByNetworkConnection(error) else { return }
        guard !showIfRequireUpdateVersion(with: error) else { return }

        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.system())
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
            flex.addItem(adsCategoryView)

            if appArchiveStatus == .done {
                flex.addItem(fbIncomeView)
            } else {
                flex.addItem(moreInsightsComingView)
            }
        }

        scroll.addSubview(insightView)
        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem(scroll).height(100%)
        }
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

extension InsightViewController {
    fileprivate func makeHeadingView() -> HeadingView {
        let headingView = HeadingView()
        headingView.setHeading(
            title: R.string.localizable.insights().localizedUppercase,
            color:  ColorTheme.internationalKleinBlue.color)
        headingView.subTitle = R.string.localizable.howfacebookusesyoU()
        return headingView
    }

    fileprivate func makeSectionHeadingView(section: Section) -> SectionHeadingView {
        let sectionHeadingView = SectionHeadingView()
        sectionHeadingView.setProperties(section: section)
        return sectionHeadingView
    }

    fileprivate func makeFBIncomeView() -> IncomeView {
        let incomeView = IncomeView()
        incomeView.containerLayoutDelegate = self
        incomeView.setProperties(section: .fbIncome, container: self)
        return incomeView
    }

    fileprivate func makeAdsCategoryView() -> AdsCategoryView {
        let adsCategoryView = AdsCategoryView()
        adsCategoryView.containerLayoutDelegate = self
        adsCategoryView.setProperties(container: self)
        return adsCategoryView
    }

    fileprivate func makeMoreInsightsComingView() -> MoreComingView {
        let moreComingView = MoreComingView()
        moreComingView.containerLayoutDelegate = self
        moreComingView.section = .moreInsightsComing
        return moreComingView
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
}
