//
//  ReactionService.swift
//  Spring
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import RxSwift
import Moya

class ReactionService {

    static var provider = MoyaProvider<ReactionAPI>(plugins: Global.default.networkLoggerPlugin)

    static func getAll(startDate: Date, endDate: Date) -> Single<[Reaction]> {
        Global.log.info("[start] ReactionService.get(startDate, endDate)")

        TrackingRequestState.standard.syncReactionsState.accept(.loading)

        return provider.rx.requestWithRefreshJwt(.get(startDate: startDate, endDate: endDate))
            .filterSuccess()
            .map([Reaction].self, atKeyPath: "result")
            .do {
                TrackingRequestState.standard.syncReactionsState.accept(.done)
            }
    }

    static func getSpringStats(startDate: Date, endDate: Date) -> Single<Stats> {
        Global.log.info("[start] ReactionService.getSpringStats(startDate, endDate)")

        return provider.rx.requestWithRefreshJwt(.springStats(startDate: startDate, endDate: endDate))
            .filterSuccess()
            .map(StatsGroups.self, atKeyPath: "result")
            .map { try Stats(startDate: startDate, endDate: endDate, section: .reaction, statsGroups: $0) }
    }
}
