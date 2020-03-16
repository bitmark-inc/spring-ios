//
//  ReactionDataEngion+Rx.swift
//  Spring
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import SwiftDate

protocol ReactionDataEngineDelegate {
    static func fetch(with filterScope: FilterScope?) -> Results<Reaction>?
}

class ReactionDataEngine: ReactionDataEngineDelegate {
    static func fetch(with filterScope: FilterScope? = nil ) -> Results<Reaction>? {
        Global.log.info("[start] ReactionDataEngion.rx.fetch")

        do {
            guard Thread.current.isMainThread else {
                throw AppError.incorrectThread
            }

            let realm = try RealmConfig.currentRealm()
            if let filterScope = filterScope {
                guard let filterQuery = makeFilterQuery(filterScope) else {
                    throw AppError.incorrectPostFilter
                }


                return realm.objects(Reaction.self).filter(filterQuery)
            } else {
                return realm.objects(Reaction.self)
            }
        } catch {
            Global.log.error(error)
            return nil
        }
    }

    fileprivate static func makeFilterQuery(_ filterScope: FilterScope) -> NSCompoundPredicate? {
        guard let datePeriod = filterScope.datePeriod else { return nil }
        let datePredicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@",
                                        datePeriod.startDate as NSDate, datePeriod.endDate as NSDate)
        var filterPredicate: NSPredicate?

        switch filterScope.filterBy {
        case .type:
            guard let type = filterScope.filterValue as? ReactionType else { break }
            filterPredicate = NSPredicate(format: "reaction == %@", type.rawValue)
        default:
            break
        }

        var predicates: [NSPredicate] = [datePredicate]
        if let filterPredicate = filterPredicate {
            predicates.append(filterPredicate)
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
