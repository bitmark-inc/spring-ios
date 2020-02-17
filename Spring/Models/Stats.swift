//
//  Stats.swift
//  Spring
//
//  Created by Thuyen Truong on 2/11/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class Stats: Object {

    // MARK: - Properties
    @objc dynamic var id: String = ""
    @objc dynamic var sectionName: String = ""
    @objc dynamic var startDate: Date = Date()
    @objc dynamic var endDate: Date = Date()
    @objc dynamic var groups: String = ""

    override static func primaryKey() -> String? {
        return "id"
    }

    convenience init(startDate: Date, endDate: Date, section: Section, statsGroups: StatsGroups) throws {
        self.init()
        self.id = SectionTimeScope(startDate: startDate, endDate: endDate, section: section).makeID()
        self.sectionName = section.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.groups = try Converter<StatsGroups>(from: statsGroups).valueAsString
    }
}

typealias StatsGroups = [String: StatsData]

struct StatsData: Codable {
    let sysAvg: Double
    let count: Double

    enum CodingKeys: String, CodingKey {
        case sysAvg = "sys_avg"
        case count
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sysAvg = try values.decodeIfPresent(Double.self, forKey: .sysAvg) ?? 0
        count = try values.decodeIfPresent(Double.self, forKey: .count) ?? 0
    }

    public init(sysAvg: Double, count: Double) {
        self.sysAvg = sysAvg
        self.count = count
    }
}
