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
    let realmAdsCategoriesResultsRelay = BehaviorRelay<Results<UserInfo>?>(value: nil)
    let realmPostUsageResultsRelay = BehaviorRelay<Results<Usage>?>(value: nil)
    let realmReactionUsageResultsRelay = BehaviorRelay<Results<Usage>?>(value: nil)
    let realmMoodRelay = BehaviorRelay<Usage?>(value: nil)
    let realmPostStatsResultsRelay = BehaviorRelay<Results<Stats>?>(value: nil)
    let realmReactionStatsResultsRelay = BehaviorRelay<Results<Stats>?>(value: nil)

    override init() {
        super.init()

        realmAdsCategoriesResultsRelay.accept(InsightDataEngine.fetch(.adsCategory))
    }

    func fetchActivity() -> Completable {
        return FbmAccountDataEngine.syncMe()
            .observeOn(MainScheduler.asyncInstance)
            .catchError({ (error) in
                guard !AppError.errorByNetworkConnection(error) else {
                    return Completable.empty()
                }

                return Completable.error(error)
            })
            .andThen(Single.deferred {
                return Single.just(FbmAccountDataEngine.fetchMe())
            })
            .errorOnNil()
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

                self.realmPostUsageResultsRelay
                    .accept(UsageDataEngine.fetch(.post, timeUnit: timeUnit, startDate: date))
                self.realmReactionUsageResultsRelay
                    .accept(UsageDataEngine.fetch(.reaction, timeUnit: timeUnit, startDate: date))

                UsageDataEngine.sync(timeUnit: timeUnit, startDate: date)
                    .subscribe()
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    func fetchSpringStats() {
        dateRelay // ignore timeUnit change, cause when timeUnit change, it trigger date change also
            .subscribe(onNext: { [weak self] (date) in
                guard let self = self else { return }
                let timeUnit = self.timeUnitRelay.value
                let datePeriod = date.extractDatePeriod(timeUnit: timeUnit)
                let (startDate, endDate) = (datePeriod.startDate, datePeriod.endDate)

                self.realmPostStatsResultsRelay
                    .accept(StatsDataEngine.fetch(section: .post, startDate: startDate, endDate: endDate))

                self.realmReactionStatsResultsRelay
                    .accept(StatsDataEngine.fetch(section: .reaction, startDate: startDate, endDate: endDate))

                StatsDataEngine.syncPostStats(startDate: startDate, endDate: endDate)
                    .subscribe()
                    .disposed(by: self.disposeBag)

                StatsDataEngine.syncReactionStats(startDate: startDate, endDate: endDate)
                    .subscribe()
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }
}
