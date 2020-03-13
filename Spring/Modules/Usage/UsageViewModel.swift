//
//  UsageViewModel.swift
//  Spring
//
//  Created by Anh Nguyen on 11/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import RxSwift
import RxCocoa
import RealmSwift
import SwiftDate

class UsageViewModel: ViewModel {

    // MARK: - Inputs
    let dateRelay = BehaviorRelay(value: Date().in(Locales.english).dateAtStartOf(.weekOfMonth).date)
    let timeUnitRelay = BehaviorRelay<TimeUnit>(value: .week)
    let segmentDistances = BehaviorRelay<[TimeUnit: Int]>(value: [.week: 0, .year: 0, .decade: 0])

    // MARK: - Outputs
    let fetchDataResultSubject = PublishSubject<Event<Void>>()
    let realmPostUsageRelay = BehaviorRelay<Usage?>(value: nil)
    let realmReactionUsageRelay = BehaviorRelay<Usage?>(value: nil)
    let realmMoodRelay = BehaviorRelay<Usage?>(value: nil)
    let realmPostStatsRelay = BehaviorRelay<Stats?>(value: nil)
    let realmReactionStatsRelay = BehaviorRelay<Stats?>(value: nil)

    func fetchActivity() -> Completable {
        return FbmAccountDataEngine.fetchLatestFbmAccount()
            .map { try Converter<Metadata>(from: $0.metadata).value }
            .map { $0.latestActivityDate }
            .map { (latestActivityDate) -> Date in
                guard let lastActivityDate = latestActivityDate, Int(lastActivityDate.timeIntervalSince1970) != 0 else {
                    return Date()
                }
                return lastActivityDate
            }
            .flatMapCompletable { [weak self] (latestActivityDate) -> Completable in
                guard let self = self else { return Completable.never() }

                var weekDistance = 0
                var yearDistance = 0
                var decadeDistance = 0

                while latestActivityDate < Date().dateAtStartOfTimeUnit(timeUnit: .week, distance: weekDistance) {
                    weekDistance -= 1
                }

                while latestActivityDate < Date().dateAtStartOfTimeUnit(timeUnit: .year, distance: yearDistance) {
                    yearDistance -= 1
                }

                while latestActivityDate < Date().dateAtStartOfTimeUnit(timeUnit: .decade, distance: decadeDistance) {
                    decadeDistance -= 1
                }

                self.segmentDistances.accept(
                    [.week: weekDistance, .year: yearDistance, .decade: decadeDistance]
                )
                self.dateRelay.accept(latestActivityDate.in(Locales.english).dateAtStartOf(.weekOfMonth).date)

                return Completable.empty()
            }
    }

    func fetchUsage() {
        dateRelay // ignore timeUnit change, cause when timeUnit change, it trigger date change also
            .subscribe(onNext: { [weak self] (date) in
                guard let self = self else { return }
                let timeUnit = self.timeUnitRelay.value

                _ = UsageDataEngine.rx.fetchAndSyncUsage(timeUnit: timeUnit, startDate: date)
                    .catchError({ [weak self] (error) -> Single<[Section: Usage?]> in
                        self?.fetchDataResultSubject.onNext(Event.error(error))
                        return Single.just([:])
                    })
                    .asObservable()
                    .subscribe(onNext: { [weak self] (usages) in
                        guard let self = self else { return }
                        self.realmPostUsageRelay.accept(usages[.post] ?? nil)
                        self.realmReactionUsageRelay.accept(usages[.reaction] ?? nil)
                        self.realmMoodRelay.accept(usages[.mood] ?? nil)
                    })
            })
            .disposed(by: disposeBag)
    }

    func fetchSpringStats() {
        dateRelay // ignore timeUnit change, cause when timeUnit change, it trigger date change also
            .subscribe(onNext: { [weak self] (date) in
                guard let self = self else { return }
                let timeUnit = self.timeUnitRelay.value

                let datePeriod = date.extractDatePeriod(timeUnit: timeUnit)
                _ = StatsDataEngine.fetchAndSyncPostStats(startDate: datePeriod.startDate, endDate: datePeriod.endDate)
                    .catchError({ [weak self] (error) -> Single<Stats?> in
                        self?.fetchDataResultSubject.onNext(Event.error(error))
                        return Single.just(nil)
                    })
                    .subscribe(onSuccess: { [weak self] (stats) in
                        self?.realmPostStatsRelay.accept(stats)
                    })

                _ = StatsDataEngine.fetchAndSyncReactionStats(startDate: datePeriod.startDate, endDate: datePeriod.endDate)
                    .catchError({ [weak self] (error) -> Single<Stats?> in
                        self?.fetchDataResultSubject.onNext(Event.error(error))
                        return Single.just(nil)
                    })
                    .subscribe(onSuccess: { [weak self] (stats) in
                        self?.realmReactionStatsRelay.accept(stats)
                    })
            })
            .disposed(by: disposeBag)
    }
}
