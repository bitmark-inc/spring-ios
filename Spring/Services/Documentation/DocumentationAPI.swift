//
//  DocumentationAPI.swift
//  Spring
//
//  Created by Thuyen Truong on 1/20/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import Moya

enum DocumentationAPI {
    case link(linkPath: String)
}

extension DocumentationAPI: TargetType {
    var baseURL: URL {
        switch self {
        case .link(let linkPath):
            return URL(string: linkPath) ?? URL(string: "https://raw.githubusercontent.com/bitmark-inc/spring/master")!
        }
    }

    var path: String {
        return ""
    }

    var method: Moya.Method {
        return .get
    }

    var sampleData: Data {
        return Data()
    }

    var task: Task {
        return .requestPlain
    }

    var headers: [String: String]? {
        return [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
    }
}
