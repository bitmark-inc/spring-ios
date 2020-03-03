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
    var lastActivityTimestamp: Double?

    enum CodingKeys: String, CodingKey {
        case fbIdentifier = "fb-identifier"
        case lastActivityTimestamp = "last_activity_timestamp"
    }
}

extension Metadata {
    var latestActivityDate: Date? {
        guard let lastActivityTimestamp = lastActivityTimestamp else {
            return nil
        }
        return Date(timeIntervalSince1970: lastActivityTimestamp)
    }
}
