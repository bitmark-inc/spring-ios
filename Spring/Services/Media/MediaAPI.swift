//
//  MediaAPI.swift
//  Spring
//
//  Created by Thuyen Truong on 3/13/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import Moya

enum MediaAPI {
    case get(startDate: Date, endDate: Date)
}

extension MediaAPI: AuthorizedTargetType, VersionTargetType {
    var baseURL: URL {
        return URL(string: Constant.default.fBMServerURL + "/api")!
    }

    var path: String {
        switch self {
        case .get: return "photos_and_videos"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var sampleData: Data {
        return Data()
    }

    var parameters: [String: Any]? {
        var params: [String: Any] = [:]

        switch self {
        case .get(let startDate, let endDate):
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
