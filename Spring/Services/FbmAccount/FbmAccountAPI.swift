//
//  FbmAccountAPI.swift
//  Spring
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import Moya

enum FbmAccountAPI {
    case create(encryptedPublicKey: String, metadata: [String: Any])
    case getMe
    case updateMe(metadata: [String: Any])
    case deleteMe
}

extension FbmAccountAPI: AuthorizedTargetType, VersionTargetType {

    var baseURL: URL {
        return URL(string: Constant.default.fBMServerURL + "/api/accounts")!
    }

    var path: String {
        switch self {
        case .create:
            return ""
        case .getMe, .updateMe, .deleteMe:
            return "me"
        }
    }

    var method: Moya.Method {
        switch self {
        case .create:   return .post
        case .getMe:    return .get
        case .updateMe: return .patch
        case .deleteMe: return .delete
        }
    }

    var sampleData: Data {
        var dataURL: URL?
        switch self {
        case .create: dataURL = R.file.springAccountJson()
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
        case .create(let encryptedPublicKey, let metadata):
            params["enc_pub_key"] = encryptedPublicKey
            params["metadata"] = metadata
        case .getMe, .deleteMe:
            return nil
        case .updateMe(let metadata):
            params["metadata"] = metadata

        }
        return params
    }

    var task: Task {
        if let parameters = parameters {
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
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
