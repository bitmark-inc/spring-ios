//
//  FBArchiveAPI.swift
//  Spring
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Moya

enum FBArchiveAPI {
    case submit(headers: [String: String], fileURL: String, rawCookie: String, startedAt: Date?, endedAt: Date)
    case submitByURL(_ fileURL: URL)
    case getPresignedURL(_ size: Int64)
    case getAll
}

extension FBArchiveAPI: AuthorizedTargetType, VersionTargetType {
    var baseURL: URL {
        return URL(string: Constant.default.fBMServerURL + "/api/archives")!
    }

    var path: String {
        switch self {
        case .submitByURL, .submit: return "url"
        case .getAll, .getPresignedURL:
            return ""
        }
    }

    var method: Moya.Method {
        switch self {
        case .submit, .submitByURL, .getPresignedURL:
            return .post
        case .getAll:
            return .get
        }
    }

    var sampleData: Data {
        return Data()
    }

    var task: Task {
        switch self {
        case .submit(let headers, let fileURL, let rawCookie, let startedAt, let endedAt):
            let params: [String : Any] = [
                "headers": headers,
                "file_url": fileURL,
                "raw_cookie": rawCookie,
                "started_at": Int(startedAt?.timeIntervalSince1970 ?? 0),
                "ended_at": Int(endedAt.timeIntervalSince1970)
            ]

            return .requestParameters(parameters: params, encoding: JSONEncoding.default)

        case .submitByURL(let fileURL):
            let params = [
                "file_url": fileURL.absoluteString,
                "archive_type": "facebook"
            ]

            return .requestParameters(parameters: params, encoding: JSONEncoding.default)

        case .getPresignedURL(let fileSize):
            let params: [String: Any] = [
                "type": "facebook",
                "size": fileSize
            ]

            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)

        case .getAll:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        return [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
    }
}
