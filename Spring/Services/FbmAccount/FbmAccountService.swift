//
//  FbmAccountService.swift
//  Spring
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import Moya

class FbmAccountService {
    static var provider = MoyaProvider<FbmAccountAPI>(plugins: Global.default.networkLoggerPlugin)

    static func create(metadata: [String: Any]) -> Single<FbmAccount> {
        return Single.deferred {
            guard let currentAccount = Global.current.account else {
                Global.log.error(AppError.emptyCurrentAccount)
                return Single.never()
            }

            Global.log.info("[start] FbmAccountService.create")
            let encryptedPublicKey = currentAccount.encryptionKey.publicKey.hexEncodedString

            return provider.rx
                .requestWithRefreshJwt(
                    .create(encryptedPublicKey: encryptedPublicKey, metadata: metadata))
                .filterSuccess()
                .map(FbmAccount.self, atKeyPath: "result", using: Global.default.decoder)
        }
    }

    static func getMe() -> Single<FbmAccount> {
        Global.log.info("[start] FbmAccountService.getMe")

        return provider.rx
            .requestWithRefreshJwt(.getMe)
            .filterSuccess()
            .map(FbmAccount.self, atKeyPath: "result", using: Global.default.decoder )
    }

    static func updateMe(metadata: [String: Any]) -> Single<FbmAccount> {
        Global.log.info("[start] FbmAccountService.updateMe")

        return provider.rx
            .requestWithRefreshJwt(.updateMe(metadata: metadata))
            .filterSuccess()
            .map(FbmAccount.self, atKeyPath: "result", using: Global.default.decoder )
    }

    static func deleteMe() -> Completable {
        Global.log.info("[start] FbmAccountService.deleteMe")

        return provider.rx
            .requestWithRefreshJwt(.deleteMe)
            .filterSuccess()
            .asCompletable()
    }
}
