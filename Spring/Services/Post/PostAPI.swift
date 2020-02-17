//
//  PostAPI.swift
//  Spring
//
//  Created by thuyentruong on 12/3/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Moya

enum PostAPI {
    case get(startDate: Date, endDate: Date)
    case springStats(startDate: Date, endDate: Date)
}

extension PostAPI: AuthorizedTargetType, VersionTargetType {
    var baseURL: URL {
        return URL(string: Constant.default.fBMServerURL + "/api")!
    }

    var path: String {
        switch self {
        case .get: return "posts"
        case .springStats: return "stats/posts"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var sampleData: Data {
        var dataURL: URL?
        switch self {
//        case .springStats: dataURL = R.file.statsPostsJson()
        case .springStats: dataURL = R.file.statsPostsWithYourpostsJson()
        default:
            break
        }

        if let dataURL = dataURL, let data = try? Data(contentsOf: dataURL) {
            return data
        }
        return Data()
    }

    var parameters: [String: Any]? {
        var params: [String: Any] = [:]

        switch self {
        case .get(let startDate, let endDate),
             .springStats(let startDate, let endDate):
            params["started_at"] = startDate.appTimeFormat
            params["ended_at"] = endDate.appTimeFormat
        }

        return params
    }

    var task: Task {
        if let parameters = parameters {
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        }
        return .requestPlain
    }

    var headers: [String: String]? {
        return [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
    }
}
