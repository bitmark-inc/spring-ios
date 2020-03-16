//
//  PostDataEngine+Rx.swift
//  Spring
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxCocoa
import SwiftDate

enum LoadDataEvent {
    case triggerRemoteLoad
    case remoteLoaded
}

protocol PostDataEngineDelegate {
    static func fetch(with filterScope: FilterScope?) -> Results<Post>?
}

class PostDataEngine: PostDataEngineDelegate {
    static func fetch(with filterScope: FilterScope? = nil) -> Results<Post>? {
        Global.log.info("[start] PostDataEngine.rx.fetch")

        do {
            guard Thread.current.isMainThread else {
                throw AppError.incorrectThread
            }

            let realm = try RealmConfig.currentRealm()
            if let filterScope = filterScope {
                guard let filterQuery = makeFilterQuery(filterScope) else {
                    throw AppError.incorrectPostFilter
                }


                return realm.objects(Post.self).filter(filterQuery)
            } else {
                return realm.objects(Post.self)
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
            guard let type = filterScope.filterValue as? PostType else { break }
            filterPredicate = NSPredicate(format: "type == %@", type.rawValue)
        case .friend:
            if let friends = filterScope.filterValue as? [String] {
                filterPredicate = NSPredicate(format: "ANY tags.name IN %@", friends)
            } else if let friend = filterScope.filterValue as? String {
                filterPredicate = NSPredicate(format: "ANY tags.name == %@", friend)
            }
        case .place:
            if let places = filterScope.filterValue as? [String] {
                filterPredicate = NSPredicate(format: "location.name IN %@", places)
            } else if let place = filterScope.filterValue as? String {
                filterPredicate = NSPredicate(format: "location.name == %@", place)
            }
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
