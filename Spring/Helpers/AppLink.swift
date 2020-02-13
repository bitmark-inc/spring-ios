//
//  AppLink.swift
//  Spring
//
//  Created by Thuyen Truong on 1/14/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation

enum AppLink: String {
    case eula
    case privacyOfPolicy = "legal-privacy"
    case incomeQuestion = "income-question"
    case faq
    case support
    case viewRecoveryKey = "view-recovery-key"
    case exportData = "export-data"

    var path: String {
        return Constant.appName + "://\(rawValue)"
    }

    var generalText: String {
        switch self {
        case .eula:
            return R.string.phrase.eula()
        case .privacyOfPolicy:
            return R.string.phrase.privacyPolicy()
        default:
            return ""
        }
    }

    var websiteURL: URL? {
        let serverURL = "https://raw.githubusercontent.com/bitmark-inc/spring/master"

        switch self {
        case .eula:
            return URL(string: serverURL + "/eula.md")
        case .privacyOfPolicy:
            return URL(string: serverURL + "/privacy-policy.md")
        case .faq:
            return URL(string: serverURL + "/faq.md")
        default:
            return nil
        }
    }
}
