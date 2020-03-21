//
//  MediaListSectionViewController.swift
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

class MediaListSectionViewController: ViewController, BackNavigator, ListSectionDelegate {

    // MARK: - Properties
    fileprivate lazy var headingView = makeHeadingView()
    fileprivate lazy var filterSegment = makeFilterSegment()
    fileprivate lazy var collectionView = makeMediaCollectionView()
    fileprivate lazy var emptyView = makeEmptyView()
    fileprivate lazy var activityIndicator = makeActivityIndicator()

    private let sectionInsets = UIEdgeInsets(top: 1.33, left: 1.33, bottom: 0.0, right: 0.0)

    lazy var thisViewModel = viewModel as! MediaListSectionViewModel
    var timeUnitRelay = BehaviorRelay<SecondaryTimeUnit>(value: .month)
    var mediaSections = [(key: [String], value: [Media])]()

    func groupMedias(_ medias: Results<Media>, timeUnit: SecondaryTimeUnit) -> [(key: [String], value: [Media])] {
        return Dictionary(grouping: medias.sorted(byKeyPath: "timestamp", ascending: false)) { (element) -> [String] in
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

        guard let viewModel = viewModel as? MediaListSectionViewModel,
            let realmMedias = viewModel.realmMedias else { return }

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
            self.mediaSections = self.groupMedias(realmMedias, timeUnit: timeUnit)
            self.refreshView(hasData: self.mediaSections.count > 0)
            self.collectionView.reloadData()
        }).disposed(by: disposeBag)

        Observable.changeset(from: realmMedias)
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
        collectionView.isScrollEnabled = hasData
    }

    // MARK: - setup views
    override func setupViews() {
        super.setupViews()

        let backItem = makeBlackBackItem()

        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem().marginLeft(OurTheme.rowPadding).marginRight(OurTheme.rowPadding)
                    .define { (flex) in
                        flex.addItem(backItem).paddingLeft(OurTheme.rowPadding)
                        flex.addItem(headingView).padding(OurTheme.titleListSectionPaddingInset)
                        flex.addItem(filterSegment).height(40)
                    }
                flex.addItem(collectionView).grow(1).height(1)

                flex.addItem(emptyView)
                    .position(.absolute).top(200)
                    .alignSelf(.center)

                flex.addItem(activityIndicator)
                    .position(.absolute).top(250)
                    .alignSelf(.center)
            }
    }
}

extension MediaListSectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return mediaSections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaSections[section].value.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let media = mediaSections[indexPath.section].value[indexPath.row]

        if !media.isVideo {
            let cell = collectionView.dequeueReusableCell(withClass: PhotoCollectionCell.self, for: indexPath)
            cell.setData(media: media)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: VideoCollectionCell.self, for: indexPath)
            cell.videoPlayerDelegate = self
            cell.setData(media: media)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: HeaderReuseView.self, for: indexPath)
        headerView.setData(periodName: mediaSections[indexPath.section].key)
        headerView.showSeparation = false
        return headerView
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 50.0)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MediaListSectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * 2
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / 3
        return CGSize(width: widthPerItem, height: widthPerItem)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.top
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

// MARK: - VideoPlayerDelegate
extension MediaListSectionViewController: VideoPlayerDelegate {

}

// MARK: - Setup views
extension MediaListSectionViewController {
    fileprivate func makeHeadingView() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.browsePhotosVideosTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: 36),
            colorTheme: .internationalKleinBlue)
        return label
    }

    fileprivate func makeMediaCollectionView() -> UICollectionView {
        let flowlayout = UICollectionViewFlowLayout()
        flowlayout.sectionHeadersPinToVisibleBounds = true
        flowlayout.sectionFootersPinToVisibleBounds = false
        let collectionView = UICollectionView(frame: view.frame, collectionViewLayout: flowlayout)
        collectionView.backgroundColor = .clear

        collectionView.register(cellWithClass: PhotoCollectionCell.self)
        collectionView.register(cellWithClass: VideoCollectionCell.self)
        collectionView.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: HeaderReuseView.self)
        collectionView.dataSource = self
        collectionView.delegate = self

        return collectionView
    }

    fileprivate func makeActivityIndicator() -> ActivityIndicator {
        let indicator = ActivityIndicator()

        TrackingRequestState.standard.syncMediaState
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
