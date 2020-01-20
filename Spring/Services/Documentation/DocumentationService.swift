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

    static func getEula() -> Single<String> {
        return provider.rx.onlineRequest(.eula)
            .filterSuccess()
            .map({ (response) -> String in
                return String(data: response.data, encoding: .utf8) ?? ""
            })
    }
}
