//
//  PostListSectionViewController.swift
//  Spring
//
//  Created by Thuyen Truong on 3/11/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
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

class PostListSectionViewController: ViewController, BackNavigator, ListSectionDelegate {

    // MARK: - Properties
    fileprivate lazy var headingView = makeHeadingView()
    fileprivate lazy var filterSegment = makeFilterSegment()
    fileprivate lazy var tableView = makePostTableView()
    fileprivate lazy var emptyView = makeEmptyView()
    fileprivate lazy var backItem = makeBlackBackItem()

    lazy var thisViewModel = viewModel as! PostListSectionViewModel
    var timeUnitRelay = BehaviorRelay<SecondaryTimeUnit>(value: .month)
    var postSections = [(key: [String], value: [Post])]()

    func groupPosts(_ posts: Results<Post>, timeUnit: SecondaryTimeUnit) -> [(key: [String], value: [Post])] {
        return Dictionary(grouping: posts.sorted(byKeyPath: "timestamp", ascending: false)) { (element) -> [String] in
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

        guard let viewModel = viewModel as? PostListSectionViewModel,
            let realmPosts = viewModel.realmPosts else { return }

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
            self.postSections = self.groupPosts(realmPosts, timeUnit: timeUnit)
            self.tableView.reloadData()
        }).disposed(by: disposeBag)

        Observable.changeset(from: realmPosts)
            .subscribe(onNext: { [weak self] (_, _) in
                guard let self = self else { return }
                self.timeUnitRelay.accept(self.timeUnitRelay.value)
            }, onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        let backItem = makeBlackBackItem()

        tableView.dataSource = self
        tableView.delegate = self

        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem().marginLeft(OurTheme.rowPadding).marginRight(OurTheme.rowPadding)
                    .define { (flex) in
                        flex.addItem(backItem).paddingLeft(OurTheme.rowPadding)
                        flex.addItem(headingView).padding(OurTheme.titleListSectionPaddingInset)
                        flex.addItem(filterSegment).height(40)
                    }
                flex.addItem(tableView).grow(1)
                flex.addItem(emptyView)
                    .position(.absolute)
                    .top(200).left(OurTheme.paddingInset.left)
            }
    }

    fileprivate func makeEmptyView() -> Label {
        let label = Label()
        label.isDescription = true
        label.apply(
            text: R.string.phrase.postsEmpty(),
            font: R.font.atlasGroteskLight(size: 32),
            colorTheme: .black)
        label.isHidden = true
        return label
    }
}

extension PostListSectionViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return postSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postSections[section].value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = postSections[indexPath.section].value[indexPath.row]
        guard let postType = PostType(rawValue: post.type) else {
            return UITableViewCell()
        }

        let cell: PostDataTableViewCell!
        switch postType {
        case .update:
            cell = tableView.dequeueReusableCell(withClass: UpdatePostTableViewCell.self, for: indexPath)

        case .link:
            cell = tableView.dequeueReusableCell(withClass: LinkPostTableViewCell.self, for: indexPath)

        case .media:
            if post.mediaData.count > 0 {
                cell = tableView.dequeueReusableCell(withClass: MediaPostTableViewCell.self, for: indexPath)
            } else {
                fallthrough
            }

        default:
            cell = tableView.dequeueReusableCell(withClass: UpdatePostTableViewCell.self, for: indexPath)
        }
        cell.clickableDelegate = self
        cell.bindData(post: post)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader = makeSectionView(periodName: postSections[section].key)
        return makeHeaderView(sectionHeader: sectionHeader)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return makeFooterView()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.section == postSections.count - 1,
            indexPath.row == tableView.indexPathForLastRow?.row else {
            return
        }

        thisViewModel.loadMore()
    }
}

extension PostListSectionViewController: ClickableDelegate {
    func click(_ textView: UITextView, url: URL) {
        let safariVC = SFSafariViewController(url: url)
        self.present(safariVC, animated: true, completion: nil)
    }

    func playVideo(_ videoKey: String) {
        MediaService.makeVideoURL(key: videoKey)
            .subscribe(onSuccess: { [weak self] (asset) in
                guard let self = self else { return }
                let playerItem = AVPlayerItem(asset: asset)

                let player = AVPlayer(playerItem: playerItem)
                let playerVC = AVPlayerViewController()

                playerVC.player = player
                self.present(playerVC, animated: true) {
                    player.play()
                }
            }, onError: { [weak self] (error) in
                guard !AppError.errorByNetworkConnection(error) else { return }
                guard let self = self, !self.showIfRequireUpdateVersion(with: error) else { return }

                Global.log.error(error)
            })
            .disposed(by: disposeBag)
    }

    func errorWhenLoadingMedia(error: Error) {
        guard !AppError.errorByNetworkConnection(error) else { return }
        guard !showIfRequireUpdateVersion(with: error) else { return }

        Global.log.error(error)
    }
}

extension PostListSectionViewController {
    fileprivate func makeHeadingView() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.browsePostsTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: 36),
            colorTheme: .internationalKleinBlue)
        return label
    }

    fileprivate func makePostTableView() -> PostTableView {
        let tableView = PostTableView()
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }
}
