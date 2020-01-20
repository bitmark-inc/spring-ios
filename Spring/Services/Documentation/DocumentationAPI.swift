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
    case eula
}

extension DocumentationAPI: TargetType {
    var baseURL: URL {
        return URL(string: "https://raw.githubusercontent.com/bitmark-inc/spring/master")!
    }

    var path: String {
        return "eula.md"
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
