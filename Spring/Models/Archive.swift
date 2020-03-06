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
    @objc dynamic var message: String = ""
    @objc dynamic var updatedAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id
        case status, message
        case contentHash = "content_hash"
        case updatedAt = "updated_at"
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
        message = try values.decodeIfPresent(String.self, forKey: .message) ?? ""
        updatedAt = try values.decode(Date.self, forKey: .updatedAt)
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

extension Archive {
    var messageError: ArchiveMessageError? {
        return ArchiveMessageError(rawValue: message)
    }
}

enum ArchiveStatus: String {
    case submitted, stored, processed, invalid
}

enum ArchiveMessageError: String {
    case failToCreateArchive    = "FAIL_TO_CREATE_ARCHIVE"
    case failToParseArchive     = "FAIL_TO_PARSE_ARCHIVE"
    case failToDownloadArchive  = "FAIL_TO_DOWNLOAD_ARCHIVE"
    case failToExtractPost      = "FAIL_TO_EXTRACT_POST"
    case failToExtractReaction  = "FAIL_TO_EXTRACT_REACTION"
}
