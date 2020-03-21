//
//  ObservableType+observeObject.swift
//  Spring
//
//  Created by Thuyen Truong on 3/17/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import RxRealm

extension ObservableType where Element: NotificationEmitter, Element.ElementType: Object {
    func observeObject() -> Observable<Element.ElementType?> {
        return flatMap { Observable.changeset(from: $0) }
            .map { $0.0.first }
    }
}

extension ObservableType where Element == Usage? {
    func mapGroupsValue() -> Observable<Groups?> {
        return map { $0?.groupsString }
            .map { (groupsString) in
                guard let groupsString = groupsString else {
                    return nil
                }
                return try Converter<Groups>(from: groupsString).value
            }
    }
}

extension ObservableType where Element == Stats? {
    func mapGroupsValue() -> Observable<StatsGroups?> {
        return map { $0?.groupsString }
            .map { (groupsString) in
                guard let groupsString = groupsString else {
                    return nil
                }
                return try Converter<StatsGroups>(from: groupsString).value
            }
    }
}

extension ObservableType where Element == [AppArchiveStatus] {
    func mapHighestStatus() -> Observable<AppArchiveStatus> {
        return map { $0.first ?? .none }
    }

    func mapLowestStatus() -> Observable<AppArchiveStatus> {
        return map { $0.last ?? .none }
    }
}
