//
//  InsightDataEngine+Rx.swift
//  Spring
//
//  Created by Thuyen Truong on 12/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

protocol InsightDataEngineDelegate {
    static func fetch(_ userInfoKey: UserInfoKey) -> Results<UserInfo>?
    static func sync() -> Completable
    static func noExistsAdsCategories() -> Bool
}

class InsightDataEngine: InsightDataEngineDelegate {
    static let disposeBag = DisposeBag()

    static func fetch(_ userInfoKey: UserInfoKey) -> Results<UserInfo>? {
        do {
            guard Thread.current.isMainThread else {
                throw AppError.incorrectThread
            }

            let realm = try RealmConfig.currentRealm()
            return realm.objects(UserInfo.self).filter("key == %@", userInfoKey.rawValue)
        } catch {
            Global.log.error(error)
            return nil
        }
    }

    static func sync() -> Completable {
        return InsightService.getAsUserInfo()
            .flatMapCompletable { Storage.store($0) }
            .do(onError: { (error) in
                Global.backgroundErrorSubject.onNext(error)
            })
    }

    static func noExistsAdsCategories() -> Bool {
        let adsCategoriesResults = InsightDataEngine.fetch(.adsCategory)
        return adsCategoriesResults == nil || adsCategoriesResults!.count == 0
    }
}
