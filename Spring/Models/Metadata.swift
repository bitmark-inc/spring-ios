//
//  Metadata.swift
//  Spring
//
//  Created by Thuyen Truong on 1/10/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation

struct Metadata: Codable {
    var fbIdentifier: String?
    var latestActivityTimestamp: Double?
    var automate: Bool?

    enum CodingKeys: String, CodingKey {
        case fbIdentifier = "fb-identifier"
        case latestActivityTimestamp = "latest_activity_timestamp"
        case automate
    }
}

extension Metadata {
    var latestActivityDate: Date? {
        guard let latestActivityTimestamp = latestActivityTimestamp else {
            return nil
        }
        return Date(timeIntervalSince1970: latestActivityTimestamp)
    }
}
