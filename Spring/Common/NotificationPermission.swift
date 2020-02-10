//
//  NotificationPermission.swift
//  Spring
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import UserNotifications

class NotificationPermission {
    static func askForNotificationPermission(handleWhenDenied: Bool) -> Single<UNAuthorizationStatus> {
        return Single<UNAuthorizationStatus>.create { (event) -> Disposable in
            let notificationCenter = UNUserNotificationCenter.current()

            notificationCenter.getNotificationSettings { (settings) in

                let notifyStatus = settings.authorizationStatus
                switch notifyStatus {
                case .notDetermined:
                    let options: UNAuthorizationOptions = [.alert, .sound, .badge]
                    notificationCenter.requestAuthorization(options: options) { (didAllow, error) in
                        if let error = error {
                            event(.error(error))
                        } else {
                            didAllow ? event(.success(.authorized)) : event(.success(.denied))
                        }
                    }

                case .denied:
                    handleWhenDenied ? askEnableNotificationAlert() : event(.success(.denied))

                case .authorized, .provisional:
                    event(.success(notifyStatus))
                @unknown default:
                    break
                }
            }

            return Disposables.create()
        }
    }

    fileprivate static func askEnableNotificationAlert() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: R.string.error.notificationTitle(),
                message: R.string.error.notificationMessage(),
                preferredStyle: .alert)

            let cancelAction = UIAlertAction(
                title: R.string.localizable.cancel(),
                style: .cancel, handler: nil)

            let enableAction = UIAlertAction(
                title: R.string.localizable.enable(),
                style: .default, handler: self.openAppSettings)

            alertController.addAction(cancelAction)
            alertController.addAction(enableAction)
            alertController.preferredAction = enableAction

            alertController.show()
        }
    }

    @objc static func openAppSettings(_ sender: UIAlertAction) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
