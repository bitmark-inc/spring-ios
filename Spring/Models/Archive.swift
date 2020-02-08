//
//  Archive.swift
//  Spring
//
//  Created by Thuyen Truong on 12/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class Archive: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var id: Int64 = 0
    @objc dynamic var status: String = ""
    @objc dynamic var contentHash: String = ""
    @objc dynamic var issueBitmark: Bool = false

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case contentHash = "content_hash"
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int64.self, forKey: .id)
        status = try values.decode(String.self, forKey: .status)
        contentHash = try values.decodeIfPresent(String.self, forKey: .contentHash) ?? ""
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

enum ArchiveStatus: String {
    case submitted, stored, processed, invalid
}
