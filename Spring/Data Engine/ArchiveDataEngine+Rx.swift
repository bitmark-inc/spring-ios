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

protocol ArchiveDataEngineDelegate {
    static func store(_ archives: [Archive]) -> Completable
    static func issueBitmarkIfNeeded() -> Completable
    static func fetchAppArchiveStatus() -> Single<AppArchiveStatus>
}

class ArchiveDataEngine: ArchiveDataEngineDelegate {
    static func fetchAppArchiveStatus() -> Single<AppArchiveStatus> {
        return FBArchiveService.getAll()
            .do(onSuccess: { (archives) in
                _ = ArchiveDataEngine.store(archives)
                    .andThen(ArchiveDataEngine.issueBitmarkIfNeeded())
                    .subscribe(onCompleted: {
                        Global.log.info("[done] storeAndIssueBitmarkIfNeeded")
                    }, onError: { (error) in
                        Global.log.error(error)
                    })
            })
            .map { (archives) -> AppArchiveStatus in
                guard archives.count > 0 else {
                    return .none
                }

                if archives.contains(where: { $0.status == ArchiveStatus.processed.rawValue }) {
                    return .processed
                } else if archives.contains(where: { [ArchiveStatus.submitted.rawValue, ArchiveStatus.processing.rawValue].contains($0.status) }) {
                    return .processing
                } else {
                    let sortedInvalidArchiveIDs = archives
                        .filter { $0.status == ArchiveStatus.invalid.rawValue }
                        .sorted { $0.updatedAt > $1.updatedAt }

                    if let latestInvalidArchive = sortedInvalidArchiveIDs.first {
                        switch latestInvalidArchive.messageError {
                        case .failToCreateArchive, .failToDownloadArchive:
                            return .invalid(sortedInvalidArchiveIDs.map { $0.id }, latestInvalidArchive.messageError)
                        default:
                            return .processing
                        }

                    } else if archives.contains(where: { $0.status == ArchiveStatus.created.rawValue }) {
                        return .created
                    } else {
                        return .processing
                    }
                }
            }
    }

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
                        let archives = realm.objects(Archive.self).filter({ !$0.issueBitmark && $0.status == ArchiveStatus.processed.rawValue && $0.contentHash != "" })
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
                                        let appInfoSingle = ServerAssetsService.getAppInformation().asObservable().share()
                                        let eulaSingle = appInfoSingle.flatMap { DocumentationService.get(linkPath: $0.docs.eula) }

                                        return Observable.zip(appInfoSingle, eulaSingle)
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
                                            .asSingle()
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
                                        guard !AppError.errorByNetworkConnection(error) else { return }
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
