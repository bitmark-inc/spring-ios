//
//  ReactionDataEngion+Rx.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import SwiftDate

class ReactionDataEngine {

    static var datePeriodSubject: PublishSubject<DatePeriod>?

    static func sync(datePeriod: DatePeriod?) throws {
        guard let datePeriod = datePeriod else { return }

        datePeriodSubject = PublishSubject<DatePeriod>()

        let realm = try RealmConfig.currentRealm()
        let queryTrack = realm.object(ofType: QueryTrack.self, forPrimaryKey: RemoteQuery.reactions.rawValue)
        let trackedDatePeriods = queryTrack?.datePeriods ?? []
        let rootEndDate = datePeriod.endDate

        var syncedStartDate: Date = Date()

        _ = datePeriodSubject?
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onNext: { (datePeriod) in
                let (startDate, endDate) = (datePeriod.startDate, datePeriod.endDate)
                _ = fetchRemote(startDate: startDate, endDate: endDate)
                    .subscribe(onSuccess: { (syncedSt) in
                        loadingState.onNext(.hide)
                        syncedStartDate = syncedSt

                        if syncedStartDate <= startDate {
                            datePeriodSubject?.onCompleted()
                        } else {
                            Self.datePeriodSubject?.onNext(
                                DatePeriod(startDate: startDate, endDate: syncedStartDate - 1.seconds))
                        }
                    }, onError: { (error) in
                        guard !AppError.errorByNetworkConnection(error) else { return }
                        Global.log.error(error)
                    })
            }, onError: { (error) in
                if let error = error as? AppError {
                    switch error {
                    case .didRemoteQuery: break
                    default:
                        Global.log.error(error)
                    }
                } else {
                    Global.log.error(error)
                }
            }, onCompleted: {
                QueryTrack.store(
                    trackedDatePeriods: trackedDatePeriods, in: .reactions,
                    syncedDatePeriod: DatePeriod(startDate: syncedStartDate, endDate: rootEndDate))
            })

        if queryTrack?.didQuery(with: datePeriod) ?? false {
            loadingState.onNext(.hide)
            datePeriodSubject?.onError(AppError.didRemoteQuery) // this is not error, just track to ignore waste to store QueryTrack
        } else {
            datePeriodSubject?.onNext(datePeriod)
        }
    }

    static func fetchRemote(startDate: Date, endDate: Date) -> Single<Date> {
        return ReactionService.getAll(startDate: startDate, endDate: endDate)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMap({ (reactions) -> Single<Date> in
                let syncedStartDate = reactions.compactMap { $0.timestamp }.min() ?? startDate
                return Storage.store(reactions)
                    .andThen(Single.just(syncedStartDate))
            })
    }
}

extension ReactionDataEngine: ReactiveCompatible {}

extension Reactive where Base: ReactionDataEngine {

    static func fetch(with filterScope: FilterScope) -> Single<Results<Reaction>> {
        Global.log.info("[start] ReactionDataEngion.rx.fetch")

        return Single<Results<Reaction>>.create { (event) -> Disposable in
            do {
                guard Thread.current.isMainThread else {
                    throw AppError.incorrectThread
                }

                let realm = try RealmConfig.currentRealm()

                guard let filterQuery = makeFilterQuery(filterScope) else {
                    throw AppError.incorrectReactionFilter
                }
                let reactions = realm.objects(Reaction.self).filter(filterQuery)
                event(.success(reactions))

                if reactions.count == 0 { loadingState.onNext(.loading) }

                let datePeriod = extractQueryDatePeriod(filterScope)
                try ReactionDataEngine.sync(datePeriod: datePeriod)
            } catch {
                event(.error(error))
            }

            return Disposables.create()
        }
    }

    static func makeFilterQuery(_ filterScope: FilterScope) -> NSCompoundPredicate? {
        guard let datePeriod = extractQueryDatePeriod(filterScope) else { return nil }
        let datePredicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@",
                                        datePeriod.startDate as NSDate, datePeriod.endDate as NSDate)
        var filterPredicate: NSPredicate?

        switch filterScope.filterBy {
        case .type:
            guard let type = filterScope.filterValue as? ReactionType else { break }
            filterPredicate = NSPredicate(format: "reaction == %@", type.rawValue)
        default:
            break
        }

        var predicates: [NSPredicate] = [datePredicate]
        if let filterPredicate = filterPredicate {
            predicates.append(filterPredicate)
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    static func extractQueryDatePeriod(_ filterScope: FilterScope) -> DatePeriod? {
        let timeUnit = filterScope.timeUnit

        switch filterScope.filterBy {
        case .day:
            guard let filterDay = filterScope.filterValue as? Date
                else {
                    Global.log.error("formatInDay is incorrect.")
                    return nil
            }

            return filterDay.extractSubPeriod(timeUnit: timeUnit)
        default:
            return filterScope.date.extractDatePeriod(timeUnit: timeUnit)
        }
    }
}
