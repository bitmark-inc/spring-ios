//
//  Deeplink.swift
//  Spring
//
//  Created by Thuyen Truong on 1/20/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK

enum DeeplinkHost: String {
    case login = "login"
}

class Deeplink {
    static func generateDeeplink(host: DeeplinkHost, params: [String: Any] = [:]) -> String? {
        switch host {
        case .login:
            guard let account = params["account"] as? Account else {
                return nil
            }

            var phrasesParams = ""
            do {
                phrasesParams = try account.getRecoverPhrase(language: .english).joined(separator: "-")
            } catch {
                Global.log.error(error)
            }
            return Constant.appStoreURLScheme + "://\(host.rawValue)?phrases=" + phrasesParams
        }
    }
}
