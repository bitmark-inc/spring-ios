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
    let realmInsightsInfoRelay = BehaviorRelay<UserInfo?>(value: nil)
    let realmAdsCategoriesRelay = BehaviorRelay<UserInfo?>(value: nil)

    func fetchQuickInsight() {
        realmAdsCategoriesRelay.accept(InsightDataEngine.fetchAdsCategoriesInfo())
    }

    func fetchInsight() {
        InsightDataEngine.rx.fetchAndSyncInsight()
            .catchError({ [weak self] (error) -> Single<UserInfo?> in
                self?.fetchDataResultSubject.onNext(Event.error(error))
                return Single.just(nil)
            })
            .asObservable()
            .subscribe(onNext: { [weak self] (insightsInfo) in
                guard let self = self else { return }
                self.realmInsightsInfoRelay.accept(insightsInfo)
            })
            .disposed(by: disposeBag)
    }
}
