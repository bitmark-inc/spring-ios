//
//  PostListViewController.swift
//  Spring
//
//  Created by thuyentruong on 12/2/19.
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
import AVKit
import AVFoundation
import MediaPlayer
import AudioToolbox

class PostListViewController: ViewController, BackNavigator {

    // MARK: - Properties
    fileprivate lazy var tableView = PostTableView()
    fileprivate lazy var emptyView = makeEmptyView()
    fileprivate lazy var backItem = makeBlackBackItem()
    fileprivate lazy var activityIndicator = makeActivityIndicator()

    lazy var thisViewModel = viewModel as! PostListViewModel

    // MARK: - bind ViewModel
    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? PostListViewModel,
            let realmPost = viewModel.realmPosts else { return }

        Observable.changeset(from: realmPost)
            .subscribe(onNext: { [weak self] (_, _) in
                guard let self = self else { return }
                self.refreshView()
                self.tableView.reloadData()
            }, onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: disposeBag)
    }

    func refreshView() {
        let hasPosts = thisViewModel.realmPosts != nil && !thisViewModel.realmPosts!.isEmpty
        emptyView.isHidden = hasPosts
        tableView.isScrollEnabled = hasPosts
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

extension PostListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return thisViewModel.realmPosts?.count ?? 0
        default:
            return 0
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
            let post = thisViewModel.realmPosts![indexPath.row]
            let cell = PostTableView.extractPostCell(with: post, tableView, indexPath)
            cell.clickableDelegate = self
            cell.videoPlayerDelegate = self
            cell.bindData(post: post)
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
        return section == 1 ? PostTableView.makeFooterView() : nil
    }
}

// MARK: - ClickableDelegate, VideoPlayerDelegate
extension PostListViewController: ClickableDelegate, VideoPlayerDelegate {
    func click(_ textView: UITextView, url: URL) {
        if url.scheme == Constant.appName {
            guard let host = url.host,
                let filterBy = GroupKey(rawValue: host)
                else {
                    return
            }

            let filterValue = url.lastPathComponent
            gotoPostListScreen(filterBy: filterBy, filterValue: filterValue)
        } else {
            let safariVC = SFSafariViewController(url: url)
            self.present(safariVC, animated: true, completion: nil)
        }
    }

    func errorWhenLoadingMedia(error: Error) {
        guard !AppError.errorByNetworkConnection(error) else { return }
        guard !showIfRequireUpdateVersion(with: error) else { return }

        Global.log.error(error)
    }
}

// MARK: - Navigator
extension PostListViewController {
    func gotoPostListScreen(filterBy: GroupKey, filterValue: String) {
        guard let currentFilterScope = thisViewModel.filterScope else { return }
        loadingState.onNext(.loading)
        let newFilterScope = FilterScope(
            date: currentFilterScope.date, timeUnit: currentFilterScope.timeUnit,
            section: .post,
            filterBy: filterBy, filterValue: filterValue)

        let postListviewModel = PostListViewModel(filterScope: newFilterScope)
        navigator.show(segue: .postList(viewModel: postListviewModel), sender: self)
    }
}

// MARK: - Setup views
extension PostListViewController {
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

    fileprivate func makeActivityIndicator() -> ActivityIndicator {
        let indicator = ActivityIndicator()

        TrackingRequestState.standard.syncPostsState
            .map { $0 == .loading }
            .bind(to: indicator.rx.isAnimating)
            .disposed(by: disposeBag)

        return indicator
    }
}
