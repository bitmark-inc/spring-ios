//
//  SyncLoadMoreDataEngine.swift
//  Spring
//
//  Created by Thuyen Truong on 3/13/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import SwiftDate

enum RemoteQuery: String {
    case posts
    case reactions
    case media
}

class SyncLoadDataEngine {

    // MARK: - Properties
    let datePeriod: DatePeriod!
    let remoteQuery: RemoteQuery!
    var currentDatePeriod: DatePeriod?
    var isCompleted: Bool = false

    var lock = NSLock()

    init(datePeriod: DatePeriod, remoteQuery: RemoteQuery) {
        self.datePeriod = datePeriod
        self.remoteQuery = remoteQuery
        self.currentDatePeriod = doShortenPeriod(for: datePeriod)
    }

    deinit {
        storeQueryTrack()
    }

    func sync() -> Completable {
        guard lock.try() else { return Completable.never() }

        guard let currentDatePeriod = currentDatePeriod, !isCompleted else {
            isCompleted = true
            return Completable.empty()
        }

        let (startDate, endDate) = (currentDatePeriod.startDate, currentDatePeriod.endDate)
        return fetchRemote(startDate: startDate, endDate: endDate)
            .flatMapCompletable({ [weak self] (sycnedStartDate) -> Completable in
                guard let self = self else { return Completable.never() }

                if sycnedStartDate <= startDate {
                    self.currentDatePeriod?.endDate = self.datePeriod.startDate
                    self.isCompleted = true
                } else {
                    self.currentDatePeriod?.endDate = sycnedStartDate - 1.seconds
                }

                return Completable.empty()
            })
            .do(onError: { [weak self] (_) in self?.lock.unlock() },
                onCompleted: { [weak self] in self?.lock.unlock() }
            )
    }

    // fetch - store posts / reactions; and returns earlest startDate - syncedStartDate
    fileprivate func fetchRemote(startDate: Date, endDate: Date) -> Single<Date> {
        switch remoteQuery {
        case .posts:
            return PostService.getAll(startDate: startDate, endDate: endDate)
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .flatMap({ (posts) -> Single<Date> in
                    let syncedStartDate = posts.compactMap { $0.timestamp }.min() ?? startDate
                    return Storage.store(posts)
                        .andThen(Single.just(syncedStartDate))
                })

        case .reactions:
            return ReactionService.getAll(startDate: startDate, endDate: endDate)
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .flatMap({ (reactions) -> Single<Date> in
                    let syncedStartDate = reactions.compactMap { $0.timestamp }.min() ?? startDate
                    return Storage.store(reactions)
                        .andThen(Single.just(syncedStartDate))
                })

        case .media:
            return MediaService.getAll(startDate: startDate, endDate: endDate)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMap({ (medias) -> Single<Date> in
                let syncedStartDate = medias.compactMap { $0.timestamp }.min() ?? startDate
                return Storage.store(medias)
                    .andThen(Single.just(syncedStartDate))
            })

        case .none:
            return Single.never()
        }
    }

    fileprivate func doShortenPeriod(for datePeriod: DatePeriod) -> DatePeriod? {
        return fetchQueryTrack()?.removeQueriedPeriod(for: datePeriod) ?? datePeriod
    }

    fileprivate func storeQueryTrack() {
        guard remoteQuery != .media,
            let currentDatePeriod = currentDatePeriod else { return }

        let trackedDatePeriods = fetchQueryTrack()?.datePeriods ?? []
        let syncedDatePeriod = DatePeriod(startDate: currentDatePeriod.endDate, endDate: datePeriod.endDate)

        QueryTrack.store(trackedDatePeriods: trackedDatePeriods, in: remoteQuery, syncedDatePeriod: syncedDatePeriod)
    }

    fileprivate func fetchQueryTrack() -> QueryTrack? {
        do {
            let realm = try RealmConfig.currentRealm()
            switch remoteQuery {
            case .posts:
                return realm.object(ofType: QueryTrack.self, forPrimaryKey: RemoteQuery.posts.rawValue)
            case .reactions:
                return realm.object(ofType: QueryTrack.self, forPrimaryKey: RemoteQuery.reactions.rawValue)
            case .media:
                return nil
            default:
                return nil
            }
        } catch {
            Global.log.error(error)
            return nil
        }
    }
}
