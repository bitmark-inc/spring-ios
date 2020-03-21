//
//  StatsDataEngine+Rx.swift
//  Spring
//
//  Created by Thuyen Truong on 2/11/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

protocol StatsDataEngineDelegate {
    static func fetch(section: Section, startDate: Date, endDate: Date) -> Results<Stats>?
    static func syncPostStats(startDate: Date, endDate: Date) -> Completable
    static func syncReactionStats(startDate: Date, endDate: Date) -> Completable
}

class StatsDataEngine: StatsDataEngineDelegate {
    static func fetch(section: Section, startDate: Date, endDate: Date) -> Results<Stats>? {
        do {
            guard Thread.current.isMainThread else {
                throw AppError.incorrectThread
            }

            let statsID = SectionTimeScope(startDate: startDate, endDate: endDate, section: section).makeID()

            let realm = try RealmConfig.currentRealm()
            return realm.objects(Stats.self).filter("id == %@", statsID)
        } catch {
            Global.log.error(error)
            return nil
        }
    }

    static func syncPostStats(startDate: Date, endDate: Date) -> Completable {
        Global.log.info("[start] StatsDataEngine.syncPostStats")

        return PostService.getSpringStats(startDate: startDate, endDate: endDate)
            .flatMapCompletable { Storage.store($0) }
            .do(onError: { (error) in
                Global.backgroundErrorSubject.onNext(error)
            })
    }

    static func syncReactionStats(startDate: Date, endDate: Date) -> Completable {
        Global.log.info("[start] StatsDataEngine.syncReactionStats")

        return ReactionService.getSpringStats(startDate: startDate, endDate: endDate)
            .flatMapCompletable { Storage.store($0) }
            .do(onError: { (error) in
                Global.backgroundErrorSubject.onNext(error)
            })
    }
}
