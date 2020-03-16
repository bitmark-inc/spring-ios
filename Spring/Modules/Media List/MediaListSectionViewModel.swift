//
//  MediaListSectionViewModel.swift
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

class MediaListSectionViewModel: ViewModel {

    // MARK: - Outputs
    var realmMedias: Results<Media>?
    var syncLoadDataEngine: SyncLoadDataEngine!

    override init() {
        super.init()
        self.syncLoadDataEngine =  SyncLoadDataEngine(
            datePeriod: DatePeriod(startDate: Constant.facebookCreationDate, endDate: Date()),
            remoteQuery: .media)

        realmMedias = MediaDataEngine.fetch()
        loadMore()
    }

    func loadMore() {
        guard let medias = realmMedias,
            !syncLoadDataEngine.isCompleted else { return }

        let trackedNumberOfMedias = medias.count

        syncLoadDataEngine.sync()
            .observeOn(MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                guard let self = self else { return }
                if medias.count <= trackedNumberOfMedias {
                    self.loadMore()
                }
            }, onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: disposeBag)
    }
}

