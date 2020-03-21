//
//  PostService.swift
//  Spring
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import Moya

class PostService {

    static var provider = MoyaProvider<PostAPI>(plugins: Global.default.networkLoggerPlugin)

    static func getAll(startDate: Date, endDate: Date) -> Single<[Post]> {
        Global.log.info("[start] PostService.get(startDate, endDate)")
        TrackingRequestState.standard.syncPostsState.accept(.loading)

        return provider.rx.requestWithRefreshJwt(.get(startDate: startDate, endDate: endDate))
            .filterSuccess()
            .map([Post].self, atKeyPath: "result")
            .do {
                TrackingRequestState.standard.syncPostsState.accept(.done)
            }
    }

    static func getSpringStats(startDate: Date, endDate: Date) -> Single<Stats> {
        Global.log.info("[start] PostService.getSpringStats(startDate, endDate)")

        return provider.rx.requestWithRefreshJwt(.springStats(startDate: startDate, endDate: endDate))
            .filterSuccess()
            .map(StatsGroups.self, atKeyPath: "result")
            .map { try Stats(startDate: startDate, endDate: endDate, section: .post, statsGroups: $0) }
    }
}
