//
//  InsightViewModel.swift
//  Spring
//
//  Created by Anh Nguyen on 11/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import RxSwift
import RxCocoa
import RealmSwift
import SwiftDate

class InsightViewModel: ViewModel {

    // MARK: - Outputs
    let fetchDataResultSubject = PublishSubject<Event<Void>>()
    let realmInsightInfoResultsRelay = BehaviorRelay<Results<UserInfo>?>(value: nil)
    let realmAdsCategoriesRelay = BehaviorRelay<UserInfo?>(value: nil)

    func fetchQuickInsight() {
        realmAdsCategoriesRelay.accept(InsightDataEngine.fetchAdsCategoriesInfo())
    }

    func fetchInsight() {
        do {
            let realmInsightResults = try InsightDataEngine.fetchInsight()
            realmInsightInfoResultsRelay.accept(realmInsightResults)

            InsightDataEngine.syncInsight()
        } catch {
            fetchDataResultSubject.onNext(Event.error(error))
        }
    }
}
