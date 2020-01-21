//
//  DocumentationService.swift
//  Spring
//
//  Created by Thuyen Truong on 1/20/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import RxSwift
import Moya

class DocumentationService {
    static var provider = MoyaProvider<DocumentationAPI>(plugins: Global.default.networkLoggerPlugin)

    static func get(linkPath: String) -> Single<String> {
        return provider.rx.onlineRequest(.link(linkPath: linkPath))
            .filterSuccess()
            .map({ (response) -> String in
                return String(data: response.data, encoding: .utf8) ?? ""
            })
    }
}
