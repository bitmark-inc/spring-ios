//
//  FbmAccountDataEngine.swift
//  Spring
//
//  Created by thuyentruong on 11/27/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

protocol FbmAccountDataEngineDelegate {
    static func createOrUpdate(isAutomate: Bool) -> Single<FbmAccount>
    static func syncMe() -> Completable
    static func fetchMe() -> FbmAccount?
}

class FbmAccountDataEngine: FbmAccountDataEngineDelegate {
    static func syncMe() -> Completable {
        return FbmAccountService.getMe()
            .flatMapCompletable { Storage.store($0) }
    }

    static func fetchMe() -> FbmAccount? {
        guard let number = Global.current.account?.getAccountNumber() else {
            Global.log.error("incorrect flow: call fetchMe when no Global.current.account")
            return nil
        }

        do {
            let realm = try RealmConfig.currentRealm()
            let me = realm.object(ofType: FbmAccount.self, forPrimaryKey: number)

            if let me = me {
                GetYourData.standard.optionRelay.accept( me.metadataInfo?.automate == false ? .manual : .automate)
            }

            return me
        } catch {
            Global.log.error(error)
            return nil
        }
    }

    static func createOrUpdate(isAutomate: Bool) -> Single<FbmAccount> {
        return Single.just(fetchMe())
            .flatMap { (fbmAccount) in
                let metadata = ["automate": isAutomate]

                guard let fbmAccount = fbmAccount else {
                    return FbmAccountService.create(metadata: metadata)
                }

                if fbmAccount.metadataInfo?.automate == isAutomate {
                    return Single.just(fbmAccount)
                } else {
                    return FbmAccountService.updateMe(metadata: metadata)
                }
            }
            .flatMap({ (fbmAccount) in
                Storage.store(fbmAccount)
                    .andThen(Single.just(fbmAccount))
            })
    }
}
