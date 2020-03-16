//
//  MediaDataEngine.swift
//  Spring
//
//  Created by Thuyen Truong on 3/15/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import SwiftDate

protocol MediaDataEngineDelegate {
    static func fetch() -> Results<Media>?
}

class MediaDataEngine: MediaDataEngineDelegate {
    static func fetch() -> Results<Media>? {
        Global.log.info("[start] MediaDataEngine.rx.fetch")

        do {
            guard Thread.current.isMainThread else {
                throw AppError.incorrectThread
            }

            let realm = try RealmConfig.currentRealm()
            return realm.objects(Media.self)
        } catch {
            Global.log.error(error)
            return nil
        }
    }
}
