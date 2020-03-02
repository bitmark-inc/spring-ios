//
//  InsightService.swift
//  Spring
//
//  Created by Thuyen Truong on 12/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import Moya

class InsightService {

    static var provider = MoyaProvider<InsightAPI>(plugins: Global.default.networkLoggerPlugin)

    static func get() -> Single<Insight> {
        Global.log.info("[start] InsightService.get")

        return provider.rx.requestWithRefreshJwt(.get)
            .filterSuccess()
            .map(Insight.self, atKeyPath: "result")
    }

    static func getAsUserInfo() -> Single<UserInfo> {
        return get()
            .map({ (insight) -> UserInfo in
                return try UserInfo(key: UserInfoKey.insight, value: insight)
            })
    }
}
