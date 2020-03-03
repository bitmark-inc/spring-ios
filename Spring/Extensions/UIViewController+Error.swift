//
//  UIViewController+Error.swift
//  Spring
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import Intercom
import SwifterSwift

extension UIViewController {
    func showErrorAlert(title: String = R.string.error.generalTitle(), message: String, buttonTitle: String = R.string.localizable.ok()) {
        showAlert(
            title: title, message: message,
            buttonTitles: [buttonTitle])
    }

    func showErrorAlert(message: String) {
        showAlert(
            title: R.string.error.generalTitle(),
            message: message,
            buttonTitles: [R.string.localizable.ok()])
    }

    func showErrorAlertWithSupport(message: String) {
        let supportMessage = R.string.localizable.supportMessage(message)
        let alertController = UIAlertController(
            title: R.string.error.generalTitle(),
            message: supportMessage,
            preferredStyle: .alert)

        let supportButton = UIAlertAction(title: R.string.localizable.contact(), style: .default) { (_) in
            Intercom.presentMessenger()
        }

        alertController.addAction(title: R.string.localizable.cancel(), style: .default, handler: nil)
        alertController.addAction(supportButton)
        alertController.preferredAction = supportButton
        alertController.show()
    }

    func handleErrorIfAsAFError(_ error: Error) -> Bool {
        guard let error = error.asAFError else {
            return false
        }

        switch error {
        case .sessionTaskFailed(let error):
            showErrorAlert(message: error.localizedDescription)
            Global.log.info("[done] handle AFError; show error: \(error.localizedDescription)")
            Global.log.error(error)
            return true

        default:
            break
        }

        return false
    }
}

struct ErrorAlert {
    static func showAuthenticationRequiredAlert(action: @escaping () -> Void) -> UIAlertController {
        let policyType = BiometricAuth.currentDeviceEvaluatePolicyType()
        let retryAuthenticationAlert = UIAlertController(
            title: R.string.error.biometricAuthRequired(policyType.text),
            message: R.string.error.biometricAuthDescription(policyType.text),
            preferredStyle: .alert)

        retryAuthenticationAlert.addAction(
            title: R.string.localizable.tryAgain(), style: .default,
            handler: { _ in action() })
        retryAuthenticationAlert.show()
        return retryAuthenticationAlert
    }

    static func invalidArchiveFileAlert(message: String, action: @escaping () -> Void) -> UIAlertController {
        let alertController = UIAlertController(
            title: R.string.error.generalTitle(),
            message: message,
            preferredStyle: .alert)

        let tryAgainButton = UIAlertAction(
            title: R.string.localizable.tryAgain(),
            style: .default, handler: { (_) in action() })

        let contactUsButotn = UIAlertAction(title: R.string.localizable.contact_us(), style: .default) { (_) in
            Intercom.presentMessenger()
        }

        alertController.addAction(tryAgainButton)
        alertController.addAction(contactUsButotn)
        return alertController
    }

    static func showErrorAlert(message: String) {
        let alertController = UIAlertController(
            title: R.string.error.generalTitle(),
            message: message,
            preferredStyle: .alert)
        alertController.addAction(title: R.string.localizable.ok(), style: .default, handler: nil)
        alertController.show()
    }

    static func showErrorAlertWithSupport(message: String) {
        let supportMessage = R.string.localizable.supportMessage(message)
        let alertController = UIAlertController(
            title: R.string.error.generalTitle(),
            message: supportMessage,
            preferredStyle: .alert)

        let supportButton = UIAlertAction(title: R.string.localizable.contact(), style: .default) { (_) in
            Intercom.presentMessenger()
        }

        alertController.addAction(title: R.string.localizable.cancel(), style: .default, handler: nil)
        alertController.addAction(supportButton)
        alertController.preferredAction = supportButton
        alertController.show()
    }
}

extension Global {
    static func handleErrorIfAsAFError(_ error: Error) -> Bool {
        guard let error = error.asAFError else {
            return false
        }

        switch error {
        case .sessionTaskFailed(let error):
            Global.log.info("[done] handle silently AFError; show error: \(error.localizedDescription)")
            Global.log.error(error)
            return true

        default:
            break
        }

        return false
    }
}
