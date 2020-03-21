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
    var firstActivityTimestamp: Double?
    var lastActivityTimestamp: Double?
    var latestActivityTimestamp: Double?
    var automate: Bool?

    enum CodingKeys: String, CodingKey {
        case fbIdentifier = "fb-identifier"
        case firstActivityTimestamp = "first_activity_timestamp"
        case lastActivityTimestamp = "last_activity_timestamp"
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

    var lastActivityDate: Date? {
        guard let lastActivityTimestamp = lastActivityTimestamp else {
            return nil
        }
        return Date(timeIntervalSince1970: lastActivityTimestamp)
    }

    var firstActivityDate: Date? {
        guard let firstActivityTimestamp = firstActivityTimestamp else {
            return nil
        }
        return Date(timeIntervalSince1970: firstActivityTimestamp)
    }
}
