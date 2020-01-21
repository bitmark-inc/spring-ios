//
//  ArchiveDataEngine+Rx.swift
//  Spring
//
//  Created by Thuyen Truong on 1/16/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import RealmSwift
import RxSwift

class ArchiveDataEngine {}

extension ArchiveDataEngine: ReactiveCompatible {}

extension Reactive where Base: ArchiveDataEngine {

    static func store(_ archives: [Archive]) -> Completable {
        return RealmConfig.rxCurrentRealm()
            .flatMapCompletable { (realm) -> Completable in
                guard let archiveProperties = realm.schema["Archive"]?.properties else {
                    return Completable.never()
                }

                let updateArchiveProperties = archiveProperties.filter { $0.name != "issueBitmark" }

                return Completable.create { (event) -> Disposable in
                    autoreleasepool { () -> Disposable in
                        for archive in archives {
                            var archivePropertyValues = [String: Any]()
                            updateArchiveProperties.forEach { archivePropertyValues[$0.name] = archive[$0.name] }
                            do {
                                try realm.write {
                                    realm.create(Archive.self, value: archivePropertyValues, update: .modified)
                                }
                            } catch {
                                event(.error(error))
                            }
                        }

                        event(.completed)
                        return Disposables.create()
                    }
                }

            }
    }

    static func issueBitmarkIfNeeded() -> Completable {
        return Completable.deferred {
            guard let account = Global.current.account else {
                return Completable.never()
            }

            return RealmConfig.rxCurrentRealm()
                .flatMapCompletable { (realm) -> Completable in
                    return Completable.create { (event) -> Disposable in
                        let archives = realm.objects(Archive.self).filter({ !$0.issueBitmark && $0.status == ArchiveStatus.processed.rawValue })
                        for archive in archives {
                                guard let assetID = RegistrationParams.computeAssetId(fingerprint: archive.contentHash)
                                    else {
                                        continue
                                }

                                let createAssetIfNeededSingle = Maybe<String>.deferred {
                                    if AssetService.getAsset(with: assetID) != nil {
                                        return AssetService.rx.existsBitmarks(issuer: account, assetID: assetID)
                                        .flatMapMaybe { $0 ? Maybe.empty() : Maybe.just(assetID) }

                                    } else {
                                        return Single.zip(ServerAssetsService.getAppInformation(), DocumentationService.getEula())
                                            .map { (appInfo, eula) -> AssetInfo in
                                                return AssetInfo(
                                                    registrant: account,
                                                    assetName: "", fingerprint: archive.contentHash,
                                                    metadata: [
                                                        "TYPE": "fbdata",
                                                        "SYSTEM_VERSION": appInfo.systemVersion,
                                                        "EULA": eula.sha3()
                                                ])
                                            }
                                            .flatMapMaybe { AssetService.rx.registerAsset(assetInfo: $0).asMaybe() }
                                    }
                                }

                                _ = createAssetIfNeededSingle
                                    .flatMap { AssetService.rx.issueBitmark(issuer: account, assetID: $0).asMaybe() }
                                    .subscribe(onSuccess: { (_) in
                                        autoreleasepool {
                                            do {
                                                try realm.write {
                                                    archive.issueBitmark = true
                                                }
                                            } catch {
                                                Global.log.error(error)
                                            }
                                        }
                                    }, onError: { (error) in
                                        Global.log.error(error)
                                    })
                            }

                        event(.completed)
                        return Disposables.create()
                    }
                }
        }
    }
}
