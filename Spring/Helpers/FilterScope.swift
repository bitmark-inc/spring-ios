//
//  FilterScope.swift
//  Spring
//
//  Created by Thuyen Truong on 12/18/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

struct FilterScope {
    let date: Date
    let timeUnit: TimeUnit
    let section: Section
    let filterBy: GroupKey
    let filterValue: Any
}

extension FilterScope {
    var datePeriod: DatePeriod? {
        switch filterBy {
        case .day:
            guard let filterDay = filterValue as? Date
                else {
                    Global.log.error("formatInDay is incorrect.")
                    return nil
            }

            return filterDay.extractSubPeriod(timeUnit: timeUnit)
        default:
            return date.extractDatePeriod(timeUnit: timeUnit)
        }
    }
}

struct SectionScope {
    let date: Date
    let timeUnit: TimeUnit
    let section: Section

    func makeID() -> String {
        let sectionName = section.rawValue
        let dateTimestamp = date.appTimeFormat
        return "\(sectionName)_\(timeUnit.rawValue)_\(dateTimestamp)"
    }
}

struct SectionTimeScope {
    let startDate: Date
    let endDate: Date
    let section: Section

    func makeID() -> String {
        let sectionName = section.rawValue
        return "\(sectionName)_\(startDate.appTimeFormat)_\(endDate.appTimeFormat)"
    }
}
