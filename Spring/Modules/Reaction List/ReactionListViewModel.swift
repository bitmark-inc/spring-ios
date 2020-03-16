//
//  ReactionListViewModel.swift
//  Spring
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import Realm
import SwiftDate

class ReactionListViewModel: ViewModel {

    // MARK: - Inputs
    let filterScope: FilterScope!
    var syncLoadDataEngine: SyncLoadDataEngine!

    // MARK: - Outputs
    var realmReactions: Results<Reaction>?

    // MARK: - Init
    init(filterScope: FilterScope) {
        self.filterScope = filterScope
        let datePeriod = filterScope.datePeriod ?? DatePeriod(startDate: Date(), endDate: Date())
        self.syncLoadDataEngine = SyncLoadDataEngine(datePeriod: datePeriod, remoteQuery: .reactions)
        super.init()

        realmReactions = ReactionDataEngine
            .fetch(with: filterScope)?
            .sorted(byKeyPath: "timestamp", ascending: false)

        if realmReactions?.count == 0 {
            loadMore()
        }
    }

    func loadMore() {
        guard let reactions = realmReactions,
            !syncLoadDataEngine.isCompleted else { return }

        let trackedNumberOfReactions = reactions.count

        syncLoadDataEngine.sync()
            .observeOn(MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                guard let self = self else { return }
                if reactions.count <= trackedNumberOfReactions {
                    self.loadMore()
                }
            }, onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: disposeBag)
    }

    func makeSectionTitle() -> String {
        return R.string.localizable.pluralReaction().localizedUppercase
    }

    func makeTaggedText() -> String? {
        return nil
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
