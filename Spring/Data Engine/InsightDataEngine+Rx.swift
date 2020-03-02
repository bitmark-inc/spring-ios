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
    static func fetchInsight() throws -> Results<UserInfo>
    static func syncInsight()
}

class InsightDataEngine: InsightDataEngineDelegate {
    static let disposeBag = DisposeBag()

    static func fetchInsight() throws -> Results<UserInfo> {
        guard Thread.current.isMainThread else {
            throw AppError.incorrectThread
        }

        let realm = try RealmConfig.currentRealm()
        return realm.objects(UserInfo.self).filter("key == %@", UserInfoKey.insight.rawValue)
    }

    static func syncInsight() {
        InsightService.getAsUserInfo()
            .flatMapCompletable { Storage.store($0) }
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onError: { (error) in
                Global.backgroundErrorSubject.onNext(error)
            })
            .disposed(by: disposeBag)
    }

    static func fetchAdsCategoriesInfo() -> UserInfo? {
        autoreleasepool {
            do {
                guard Thread.current.isMainThread else {
                    throw AppError.incorrectThread
                }

                let realm = try RealmConfig.currentRealm()
                return realm.object(ofType: UserInfo.self, forPrimaryKey: UserInfoKey.adsCategory.rawValue)
            } catch {
                Global.log.error(error)
                return nil
            }
        }
    }

    static func existsAdsCategories() -> Bool {
        autoreleasepool {
            do {
                guard Thread.current.isMainThread else {
                    throw AppError.incorrectThread
                }

                let realm = try RealmConfig.currentRealm()
                return realm.objects(UserInfo.self)
                    .filter("key == %@", UserInfoKey.adsCategory.rawValue)
                    .count > 0
            } catch {
                Global.log.error(error)
                return false
            }
        }
    }
}
