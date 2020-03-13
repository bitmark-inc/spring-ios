//
//  HomeTabbarController+Notification.swift
//  Spring
//
//  Created by Thuyen Truong on 2/7/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import UserNotifications
import OneSignal

extension HomeTabbarController {
    func registerOneSignal() {
        guard let accountNumber = Global.current.account?.getAccountNumber() else {
            Global.log.error(AppError.emptyCurrentAccount)
            return
        }

        Global.log.info("[process] registerOneSignal: \(accountNumber)")
        OneSignal.promptForPushNotifications(userResponse: { _ in
            OneSignal.sendTags([
                Constant.OneSignalTag.key: accountNumber
            ])
            OneSignal.setSubscription(true)
        })
    }
}
