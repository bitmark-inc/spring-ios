//
//  AppInfo.swift
//  Spring
//
//  Created by Thuyen Truong on 1/20/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation

struct AppInfo: Codable {
    let updateInfo: UpdateInfo
    let systemVersion: String

    enum CodingKeys: String, CodingKey {
        case updateInfo = "ios"
        case systemVersion = "system_version"
    }
}

struct UpdateInfo: Codable {
    let appUpdateURL: String
    let minimumClientVersion: Int

    enum CodingKeys: String, CodingKey {
        case appUpdateURL = "app_update_url"
        case minimumClientVersion = "minimum_client_version"
    }
}
