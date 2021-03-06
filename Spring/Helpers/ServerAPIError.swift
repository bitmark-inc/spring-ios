//
//  ServerAPIError.swift
//  Spring
//
//  Created by thuyentruong on 11/22/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import Moya

let errorKeyPath = "error"

enum APIErrorCode: Int, Codable {
    case AccountHasTaken            = 1003
    case AccountNotFound            = 1006
    case RequireUpdateVersion       = 1007
    case InvalidArchiveFile         = 2001
    case UnexpectedResponseFormat   = 500
}

extension Data {
    func convertServerAPIError() -> ServerAPIError {
        var error: ServerAPIError
        do {
            let serverError = try JSONDecoder().decode([String: ServerAPIError].self, from: self)
            if serverError.has(key: errorKeyPath) {
                error = serverError[errorKeyPath]!
            } else {
                throw "incorrect error keypath"
            }
        } catch (_) {
            error = ServerAPIError(
                code: .UnexpectedResponseFormat,
                message: String(data: self, encoding: .utf8) ?? "")
        }
        return error
    }
}

struct ServerAPIError: Codable, Error {
    let code: APIErrorCode
    let message: String
}

extension PrimitiveSequence where Trait == SingleTrait, Element == Response {
    func filterSuccess() -> Single<Element> {
        return self.flatMap { (response) -> Single<Element> in
            Global.log.debug("----- successful response -----")
            Global.log.debug(String(data: response.data, encoding: .utf8))

            if 200 ... 299 ~= response.statusCode {
                return Single.just(response)
            }

            if response.statusCode == 406 {
                return Single.error(ServerAPIError(code: .RequireUpdateVersion, message: ""))
            }

            let serverAPIError = response.data.convertServerAPIError()
            return Single.error(serverAPIError)
        }
    }
}
