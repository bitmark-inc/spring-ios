//
//  ReactionListSectionViewController.swift
//  Spring
//
//  Created by Thuyen Truong on 3/15/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import RxCocoa
import RealmSwift
import RxRealm

class ReactionListSectionViewController: ViewController, BackNavigator, ListSectionDelegate {

    // MARK: - Properties
    fileprivate lazy var headingView = makeHeadingView()
    fileprivate lazy var filterSegment = makeFilterSegment()
    fileprivate lazy var tableView = makeReactionTableView()
    fileprivate lazy var emptyView = makeEmptyView()
    fileprivate lazy var backItem = makeBlackBackItem()
    fileprivate lazy var activityIndicator = makeActivityIndicator()

    private let sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0.0, right: 0.0)

    lazy var thisViewModel = viewModel as! ReactionListSectionViewModel
    var timeUnitRelay = BehaviorRelay<SecondaryTimeUnit>(value: .month)
    var reactionSections = [(key: [String], value: [Reaction])]()

    func groupReactions(_ reactions: Results<Reaction>, timeUnit: SecondaryTimeUnit) -> [(key: [String], value: [Reaction])] {
        return Dictionary(grouping: reactions.sorted(byKeyPath: "timestamp", ascending: false)) { (element) -> [String] in
            return makeSectionElements(timeUnit: timeUnit, timestamp: element.timestamp)
        }
        .sorted { (element1, element2) -> Bool in
            guard let dateElement1 = element1.value.first?.timestamp, let dateElement2 = element2.value.first?.timestamp else {
                return true
            }
            return dateElement1 > dateElement2
        }
    }

    // MARK: - bind ViewModel
    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? ReactionListSectionViewModel,
            let realmReactions = viewModel.realmReactions else { return }

        filterSegment.rx.selectedIndex
            .map { (selectedIndex) -> SecondaryTimeUnit in
                switch selectedIndex {
                case 0: return .month
                case 1: return .year
                case 2: return .decade
                default: return .month
                }
            }.bind(to: timeUnitRelay)
            .disposed(by: disposeBag)

        timeUnitRelay.subscribe(onNext: { [weak self] (timeUnit) in
            guard let self = self else { return }
            self.reactionSections = self.groupReactions(realmReactions, timeUnit: timeUnit)
            self.refreshView(hasData: self.reactionSections.count > 0)
            self.tableView.reloadData()
        }).disposed(by: disposeBag)

        Observable.changeset(from: realmReactions)
            .subscribe(onNext: { [weak self] (_, _) in
                guard let self = self else { return }
                self.timeUnitRelay.accept(self.timeUnitRelay.value)

                }, onError: { (error) in
                    Global.log.error(error)
            })
            .disposed(by: self.disposeBag)
    }

    func refreshView(hasData: Bool) {
        emptyView.isHidden = hasData
        tableView.isScrollEnabled = hasData
    }

    // MARK: - setup views
    override func setupViews() {
        super.setupViews()

        let backItem = makeBlackBackItem()

        contentView.flex.define { (flex) in
            flex.addItem().marginLeft(OurTheme.rowPadding).marginRight(OurTheme.rowPadding)
                .define { (flex) in
                    flex.addItem(backItem).paddingLeft(OurTheme.rowPadding)
                    flex.addItem(headingView).padding(OurTheme.titleListSectionPaddingInset)
                    flex.addItem(filterSegment).height(40)
            }
            flex.addItem(tableView).grow(1).height(1)

            flex.addItem(emptyView)
                .position(.absolute).alignSelf(.center)
                .top(200)

            flex.addItem(activityIndicator)
                .position(.absolute)
                .alignSelf(.center)
                .top(250)
        }
    }
}

extension ReactionListSectionViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return reactionSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reactionSections[section].value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reaction = reactionSections[indexPath.section].value[indexPath.row]

        let cell = tableView.dequeueReusableCell(withClass: ReactionTableViewCell.self, for: indexPath)
        cell.bindData(reaction: reaction)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader = makeSectionView(periodName: reactionSections[section].key)
        return makeHeaderView(sectionHeader: sectionHeader)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return ReactionTableView.makeFooterView()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.section == reactionSections.count - 1,
            indexPath.row == tableView.indexPathForLastRow?.row else {
                return
        }

        thisViewModel.loadMore()
    }
}

extension ReactionListSectionViewController {
    fileprivate func makeHeadingView() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.browseLikesReactionsTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: 36),
            colorTheme: .internationalKleinBlue)
        return label
    }

    fileprivate func makeReactionTableView() -> ReactionTableView {
        let tableView = ReactionTableView()
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }

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
