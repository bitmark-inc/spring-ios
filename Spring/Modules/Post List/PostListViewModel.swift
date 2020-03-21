//
//  PostListViewModel.swift
//  Spring
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import Realm
import SwiftDate

class PostListViewModel: ViewModel {

    // MARK: - Inputs
    let filterScope: FilterScope!
    var syncLoadDataEngine: SyncLoadDataEngine!

    // MARK: - Outputs
    var realmPosts: Results<Post>?

    // MARK: - Init
    init(filterScope: FilterScope) {
        self.filterScope = filterScope
        let datePeriod = filterScope.datePeriod ?? DatePeriod(startDate: Date(), endDate: Date())
        self.syncLoadDataEngine = SyncLoadDataEngine(datePeriod: datePeriod, remoteQuery: .posts)
        super.init()

        realmPosts = PostDataEngine
            .fetch(with: filterScope)?
            .sorted(byKeyPath: "timestamp", ascending: false)

        if realmPosts?.count == 0 || syncLoadDataEngine.fetchQueryTrack() == nil {
            loadMore()
        }
    }

    func loadMore() {
        guard let posts = realmPosts,
            !syncLoadDataEngine.isCompleted else { return }

        let trackedNumberOfPosts = posts.count

        syncLoadDataEngine.sync()
            .observeOn(MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                guard let self = self else { return }
                if posts.count <= trackedNumberOfPosts {
                    self.loadMore()
                }
            }, onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: disposeBag)
    }

    func makeSectionTitle() -> String {
        switch filterScope.filterBy {
        case .type:
            return "plural.\(filterScope.filterValue)".localized().localizedUppercase
        default:
            return R.string.localizable.pluralPost().localizedUppercase
        }
    }

    func makeTaggedText() -> String? {
        switch filterScope.filterBy {
        case .friend, .place:
            var titleTag = ""
            if let tags = filterScope.filterValue as? [String] {
                titleTag = tags.count == 1 ? tags.first! : R.string.localizable.graphKeyOther()
            } else if let tag = filterScope.filterValue as? String {
                titleTag = tag
            }
            return R.string.phrase.postSectionTitleTag(titleTag)
        default:
            return nil
        }
    }

    func makeTimelineText() -> String? {
        let timeUnit = filterScope.timeUnit

        switch filterScope.filterBy {
        case .day:
            guard let selectedDate = filterScope.filterValue as? Date else { return nil }

            let datePeriod = selectedDate.extractSubPeriod(timeUnit: filterScope.timeUnit)
            return datePeriod.makeTimelinePeriodText(in: timeUnit.subDateComponent)
        default:
            let datePeriod = filterScope.date.extractDatePeriod(timeUnit: timeUnit)
            return datePeriod.makeTimelinePeriodText(in: timeUnit)
        }
    }
}
