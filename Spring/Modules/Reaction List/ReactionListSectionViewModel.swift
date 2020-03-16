//
//  ReactionListSectionViewModel.swift
//  Spring
//
//  Created by Thuyen Truong on 3/15/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import Realm

class ReactionListSectionViewModel: ViewModel {

    // MARK: - Outputs
    var realmReactions: Results<Reaction>?
    var syncLoadDataEngine: SyncLoadDataEngine!

    override init() {
        super.init()
        self.syncLoadDataEngine =  SyncLoadDataEngine(
            datePeriod: DatePeriod(startDate: Constant.facebookCreationDate, endDate: Date()),
            remoteQuery: .reactions)

        realmReactions = ReactionDataEngine.fetch()
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
}
