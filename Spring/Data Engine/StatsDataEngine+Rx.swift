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
    static func fetchAndSyncPostStats(startDate: Date, endDate: Date) -> Single<Stats?>
    static func fetchAndSyncReactionStats(startDate: Date, endDate: Date) -> Single<Stats?>
}

class StatsDataEngine: StatsDataEngineDelegate {
    static func fetchAndSyncPostStats(startDate: Date, endDate: Date) -> Single<Stats?> {
        return Single<Stats?>.create { (event) -> Disposable in
            autoreleasepool {
                do {
                    guard Thread.current.isMainThread else {
                        throw AppError.incorrectThread
                    }

                    let realm = try RealmConfig.currentRealm()
                    let postStatsID = SectionTimeScope(startDate: startDate, endDate: endDate, section: .post).makeID()

                    let postStats = realm.object(ofType: Stats.self, forPrimaryKey: postStatsID)

                    if postStats != nil  {
                        event(.success(postStats))

                        _ = PostService.getSpringStats(startDate: startDate, endDate: endDate)
                            .flatMapCompletable { Storage.store($0) }
                            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                            .subscribe(onError: { (error) in
                                Global.backgroundErrorSubject.onNext(error)
                            })
                    } else {
                        _ = PostService.getSpringStats(startDate: startDate, endDate: endDate)
                            .flatMapCompletable { Storage.store($0) }
                            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                            .observeOn(MainScheduler.instance)
                            .subscribe(onCompleted: {
                                let postStats = realm.object(ofType: Stats.self, forPrimaryKey: postStatsID)
                                event(.success(postStats))
                            }, onError: { (error) in
                                event(.error(error))
                            })
                    }
                } catch {
                    event(.error(error))
                }

                return Disposables.create()
            }
        }
    }

    static func fetchAndSyncReactionStats(startDate: Date, endDate: Date) -> Single<Stats?> {
        return Single<Stats?>.create { (event) -> Disposable in
            autoreleasepool {
                do {
                    guard Thread.current.isMainThread else {
                        throw AppError.incorrectThread
                    }

                    let realm = try RealmConfig.currentRealm()
                    let reactionStatsID = SectionTimeScope(startDate: startDate, endDate: endDate, section: .reaction).makeID()

                    let reactionStats = realm.object(ofType: Stats.self, forPrimaryKey: reactionStatsID)

                    if reactionStats != nil {
                        event(.success(reactionStats))

                        _ = ReactionService.getSpringStats(startDate: startDate, endDate: endDate)
                            .flatMapCompletable { Storage.store($0) }
                            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                            .subscribe(onError: { (error) in
                                Global.backgroundErrorSubject.onNext(error)
                            })
                    } else {
                        _ = ReactionService.getSpringStats(startDate: startDate, endDate: endDate)
                            .flatMapCompletable { Storage.store($0) }
                            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                            .observeOn(MainScheduler.instance)
                            .subscribe(onCompleted: {
                                let reactionStats = realm.object(ofType: Stats.self, forPrimaryKey: reactionStatsID)
                                event(.success(reactionStats))
                            }, onError: { (error) in
                                event(.error(error))
                            })
                    }
                } catch {
                    event(.error(error))
                }

                return Disposables.create()
            }
        }
    }
}
