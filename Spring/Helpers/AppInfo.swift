//
//  AppInfo.swift
//  Spring
//
//  Created by Thuyen Truong on 1/20/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation

struct AppInfo: Decodable {
    let updateInfo: UpdateInfo
    let systemVersion: String
    let docs: AppDocs

    enum CodingKeys: String, CodingKey {
        case updateInfo = "ios"
        case systemVersion = "system_version"
        case docs
    }
}

struct UpdateInfo: Decodable {
    let appUpdateURL: String
    let minimumClientVersion: Int

    enum CodingKeys: String, CodingKey {
        case appUpdateURL = "app_update_url"
        case minimumClientVersion = "minimum_client_version"
    }
}

struct AppDocs: Decodable {
    let eula: String
}
