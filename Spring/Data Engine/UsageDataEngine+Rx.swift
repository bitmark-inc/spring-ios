//
//  UsageDataEngine+Rx.swift
//  Spring
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

protocol UsageDataEngineDelegate {
    static func fetch(_ section: Section, timeUnit: TimeUnit, startDate: Date) -> Results<Usage>?
    static func sync(timeUnit: TimeUnit, startDate: Date) -> Completable
}

class UsageDataEngine: UsageDataEngineDelegate {
    static func fetch(_ section: Section, timeUnit: TimeUnit, startDate: Date) -> Results<Usage>? {
        do {
            guard Thread.current.isMainThread else {
                throw AppError.incorrectThread
            }

            let usageID = SectionScope(date: startDate, timeUnit: timeUnit, section: section).makeID()

            let realm = try RealmConfig.currentRealm()
            return realm.objects(Usage.self).filter("id == %@", usageID)
        } catch {
            Global.log.error(error)
            return nil
        }
    }

    static func sync(timeUnit: TimeUnit, startDate: Date) -> Completable {
        Global.log.info("[start] UsageDataEngine.sync")

        return UsageService.get(in: timeUnit, startDate: startDate)
                .flatMapCompletable { Storage.store($0) }
                .do(onError: { (error) in
                    Global.backgroundErrorSubject.onNext(error)
                })
    }
}
