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

    // Notification Actions
    func scheduleReminderNotificationIfNeeded() {
        guard AppArchiveStatus.currentState == .stillWaiting else { return }

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getPendingNotificationRequests { (notificationRequests) in
            guard notificationRequests.isEmpty else { return }

            // *** reset all notifications
            let content = UNMutableNotificationContent()
            content.body = R.string.phrase.dataRequestedScheduleNotifyMessage()
            content.sound = UNNotificationSound.default
            content.badge = 1

            #if targetEnvironment(simulator)
            guard let date = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) else { return }
            let triggerDate = Calendar.current.dateComponents([.second], from: date)
            #else
            guard let date = Calendar.current.date(byAdding: .minute, value: -1, to: Date()) else { return }
            let triggerDate = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
            #endif

            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
            let identifier = Constant.NotificationIdentifier.checkFBArchive
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            notificationCenter.add(request)
        }
    }

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
