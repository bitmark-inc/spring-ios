//
//  AppVersion.swift
//  Spring
//
//  Created by Thuyen Truong on 12/31/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class AppVersion {
    static func checkAppVersion() -> Completable {
        guard let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
            let buildVersionNumber = Int(bundleVersion)
            else {
                return Completable.never()
        }

        return Completable.create { (event) -> Disposable in
            _ = ServerAssetsService.getAppInformation()
                .map { $0.updateInfo }
                .subscribe(onSuccess: { (iosInfo) in
                    let minimumClientVersion = iosInfo.minimumClientVersion
                    let appUpdatePath = iosInfo.appUpdateURL

                    if buildVersionNumber < minimumClientVersion {
                        guard let appUpdateURL = URL(string: appUpdatePath) else { return }
                        event(.error(AppError.requireAppUpdate(updateURL: appUpdateURL)))
                    } else {
                        event(.completed)
                    }
                }, onError: { (error) in
                    AppError.errorByNetworkConnection(error) ?
                        event(.completed) : // works as offline mode
                        event(.error(error))
                })

            return Disposables.create()
        }
    }

    static func showAppRequireUpdateAlert(updateURL: URL) {
        let alertController = UIAlertController(
            title: R.string.localizable.requireAppUpdateTitle(),
            message: R.string.localizable.requireAppUpdateMessage(),
            preferredStyle: .alert)

        let action = UIAlertAction(title: R.string.localizable.requireAppUpdateAction(), style: .default) { (_) in
            UIApplication.shared.open(updateURL)
        }
        alertController.addAction(action)
        alertController.preferredAction = action

        alertController.show()
    }
}

extension UIViewController {
    func showIfRequireUpdateVersion(with error: Error) -> Bool {
        if let error = error as? ServerAPIError {
            switch error.code {
            case .RequireUpdateVersion:
                _ = ServerAssetsService.getAppInformation()
                    .map { $0.updateInfo }
                    .subscribe(onSuccess: { (iosInfo) in
                        let appUpdatePath = iosInfo.appUpdateURL
                        guard let appUpdateURL = URL(string: appUpdatePath)
                            else {
                                return
                        }
                        AppVersion.showAppRequireUpdateAlert(updateURL: appUpdateURL)
                    }, onError: { [weak self] (error) in
                        guard let self = self,
                            !AppError.errorByNetworkConnection(error) else { return }
                        Global.log.error(error)
                        self.showErrorAlertWithSupport(message: R.string.error.requestData())
                    })
                return true

            default:
                return false
            }
        }
        return false
    }
}
