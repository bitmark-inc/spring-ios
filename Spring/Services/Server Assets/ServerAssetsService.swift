//
//  ServerAssetsService.swift
//  Spring
//
//  Created by thuyentruong on 11/22/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import Moya

class ServerAssetsService {

    static var provider = MoyaProvider<ServerAssetsAPI>(plugins: Global.default.networkLoggerPlugin)

    static func getFBAutomation() -> Single<[FBScript]> {
        Global.log.info("[start] getFBAutomation")

        return provider.rx
            .onlineRequest(.fbAutomation)
            .filterSuccess()
            .map([FBScript].self, atKeyPath: "pages")
    }

    static func getAppInformation() -> Single<AppInfo> {
        Global.log.info("[start] getAppInformation")

        return provider.rx
            .onlineRequest(.appInformation)
            .filterSuccess()
            .map(AppInfo.self, atKeyPath: "information")
    }
}
