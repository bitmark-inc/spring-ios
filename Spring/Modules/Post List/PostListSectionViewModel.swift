//
//  PostListSectionViewModel.swift
//  Spring
//
//  Created by Thuyen Truong on 3/11/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import Realm

class PostListSectionViewModel: ViewModel {

    // MARK: - Outputs
    var realmPosts: Results<Post>?
    var syncLoadDataEngine: SyncLoadDataEngine!

    override init() {
        super.init()
        self.syncLoadDataEngine =  SyncLoadDataEngine(
            datePeriod: DatePeriod(startDate: Constant.facebookCreationDate, endDate: Date()),
            remoteQuery: .posts)

        realmPosts = PostDataEngine.fetch()
        if realmPosts?.count == 0 {
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
}
