//
//  ReactionListViewController.swift
//  Spring
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import RxCocoa
import SwiftDate
import RealmSwift
import RxRealm
import SafariServices

class ReactionListViewController: ViewController, BackNavigator {

    // MARK: - Properties
    fileprivate lazy var tableView = ReactionTableView()
    fileprivate lazy var emptyView = makeEmptyView()
    fileprivate lazy var backItem = makeBlackBackItem()
    fileprivate lazy var activityIndicator = makeActivityIndicator()

    lazy var thisViewModel = viewModel as! ReactionListViewModel

    // MARK: - bind ViewModel
    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? ReactionListViewModel,
            let realmReactions = viewModel.realmReactions else { return }

        Observable.changeset(from: realmReactions)
            .subscribe(onNext: { [weak self] (_, _) in
                guard let self = self else { return }
                self.refreshView()
                self.tableView.reloadData()
            }, onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: self.disposeBag)
    }

    func refreshView() {
        let hasReactions = thisViewModel.realmReactions != nil && !thisViewModel.realmReactions!.isEmpty
        emptyView.isHidden = hasReactions
        tableView.isScrollEnabled = hasReactions
    }

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        loadingState.onNext(.hide)

        tableView.dataSource = self
        tableView.delegate = self

        contentView.flex
            .direction(.column).alignContent(.center).define { (flex) in
                flex.addItem(tableView).grow(1).height(1)

                flex.addItem(emptyView)
                    .position(.absolute).top(200)
                    .alignSelf(.center)

                flex.addItem(activityIndicator)
                    .position(.absolute).top(250)
                    .alignSelf(.center)
            }
    }
}

extension ReactionListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:     return 1
        case 1:     return thisViewModel.realmReactions?.count ?? 0
        default:    return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withClass: ListHeadingViewCell.self, for: indexPath)
            cell.fillInfo(
                backButton: backItem,
                sectionInfo: (
                    sectionTitle: thisViewModel.makeSectionTitle(),
                    taggedText: thisViewModel.makeTaggedText(),
                    timelineText: thisViewModel.makeTimelineText()))

            return cell

        case 1:
            let reaction = thisViewModel.realmReactions![indexPath.row]
            let cell = tableView.dequeueReusableCell(withClass: ReactionTableViewCell.self, for: indexPath)
            cell.bindData(reaction: reaction)
            return cell

        default:
            return tableView.dequeueReusableCell(withClass: ListHeadingViewCell.self, for: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let lastIndexPathInItemsSection = tableView.indexPathForLastRow(inSection: 1), indexPath.section == 1
            else {
                return
        }

        if indexPath.row == lastIndexPathInItemsSection.row {
            thisViewModel.loadMore()
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 1 ? 10 : 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return section == 1 ? ReactionTableView.makeFooterView() : nil
    }
}

// MARK: - Setup views
extension ReactionListViewController {
    fileprivate func makeActivityIndicator() -> ActivityIndicator {
        let indicator = ActivityIndicator()

        TrackingRequestState.standard.syncReactionsState
            .map { $0 == .loading }
            .bind(to: indicator.rx.isAnimating)
            .disposed(by: disposeBag)

        return indicator
    }

    fileprivate func makeEmptyView() -> Label {
        let label = Label()
        label.isDescription = true
        label.apply(
            text: R.string.localizable.graphNoActivity(),
            font: R.font.atlasGroteskLight(size: 18),
            colorTheme: .tundora)
        label.isHidden = true
        return label
    }
}
