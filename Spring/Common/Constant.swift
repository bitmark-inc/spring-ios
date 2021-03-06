//
//  Constant.swift
//  Spring
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

public struct Constant {
    static let `default` = Constant()

    public struct NotificationIdentifier {
        public static let checkFBArchive = "checkFBArchiveIdentifier"
    }

    // MARK: - Info Credential
    let zeroAccountNumber = Credential.valueForKey(keyName: "ZERO_ADDRESS")
    let stripePublishableKey = Credential.valueForKey(keyName: "STRIPE_PUBLISHABLE_KEY")
    let googleAPIClientID = Credential.valueForKey(keyName: "YOUTUBE_CLIENT_ID")
    let intercomAppID = Credential.valueForKey(keyName: "INTERCOM_APP_ID")
    let intercomAppKey = Credential.valueForKey(keyName: "INTERCOM_APP_KEY")
    let appleMerchantID = Credential.valueForKey(keyName: "APPLE_MERCHANT_ID")
    let sentryDSN = Credential.valueForKey(keyName: "SENTRY_DSN")
    let oneSignalAppID = Credential.valueForKey(keyName: "ONESIGNAL_APP_ID")
    let fBMServerURL = Credential.valueForKey(keyName: "API_FBM_SERVER_URL")

    static let appName = "Spring"
    static let supportEmail = "support@bitmark.com"
    public static let productLink = "https://apps.apple.com/us/app/bitmark/id1429427796"
    let numberOfPhrases = 12
    
    struct TimeFormat {
        static let post = "MMM d 'at' h:mm a"
        static let reaction = "MMM d 'at' h:mm a"
        static let archive = "MMM d 'at' h:mm a"
        static let full = "YYYY MMM d"
        static let short = "MMM d"
        static let date = "MMM d, YYYY"
    }

    public struct OneSignalTag {
        public static let key = "account_id"
    }

    static var appURLScheme: String {
        if let bundleURLTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]],
            let urlSchemes = bundleURLTypes.first?["CFBundleURLSchemes"] as? [String] {
            return urlSchemes.first ?? ""
        }

        return ""
    }

    static let appStoreURLScheme = "com.spring"

    static let separator = ","
    static let fbImageServerURL = Credential.valueForKey(keyName: "API_FBM_SERVER_URL") + "/api/media"
    static let surveyURL = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLScL41kNU6SBzo7ndcraUf7O-YJ_JrPqg_rlI588UjLK-_sGtQ/viewform?usp=sf_link")!
}
