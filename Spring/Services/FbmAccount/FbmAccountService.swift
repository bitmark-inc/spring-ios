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

    static func fetchOverallArchiveStatus() -> Single<ArchiveStatus?> {
        return Single.create { (event) -> Disposable in
            _ = FBArchiveService.getAll()
                .do(onSuccess: { (archives) in
                    _ = ArchiveDataEngine.rx.store(archives)
                        .andThen(ArchiveDataEngine.rx.issueBitmarkIfNeeded())
                        .subscribe(onCompleted: {
                            Global.log.info("[done] storeAndIssueBitmarkIfNeeded")
                        }, onError: { (error) in
                            Global.log.error(error)
                        })
                })
                .subscribe(onSuccess: { (archives) in
                    guard archives.count > 0 else {
                        event(.success(nil))
                        return
                    }

                    if archives.firstIndex(where: { $0.status == ArchiveStatus.processed.rawValue }) != nil {
                        event(.success(.processed))
                    } else {
                        let notInvalidArchives = archives.filter { $0.status != ArchiveStatus.invalid.rawValue }
                        event(.success( notInvalidArchives.isEmpty ? .invalid : .submitted ))
                    }
                }, onError: { (error) in
                    event(.error(error))
                })

            return Disposables.create()
        }
    }
}
