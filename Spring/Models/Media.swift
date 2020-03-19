//
//  Media.swift
//  Spring
//
//  Created by Thuyen Truong on 3/15/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import SwiftDate

class Media: Object, Decodable {
    @objc dynamic var id: String = ""
    @objc dynamic var source: String = ""
    @objc dynamic var thumbnail: String = ""
    @objc dynamic var `extension`: String = ""
    @objc dynamic var timestamp: Date = Date()

    override class func primaryKey() -> String? {
        return "id"
    }

    enum CodingKeys: String, CodingKey {
        case id, source, thumbnail, `extension`, timestamp
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        source = try values.decode(String.self, forKey: .source)
        thumbnail = try values.decode(String.self, forKey: .thumbnail)
        `extension` = try values.decode(String.self, forKey: .extension)
        let timestampInterval = try values.decode(Double.self, forKey: .timestamp)
        timestamp = Date(timeIntervalSince1970: timestampInterval)
    }

    // MARK: - Realm Required Init
    required init() {
        super.init()
    }

    override init(value: Any) {
        super.init(value: value)
    }

    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }

    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
}

extension Media {
    var isVideo: Bool {
        return Constant.fbVideoExtensions.contains(`extension`)
    }
}
