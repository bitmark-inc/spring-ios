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
    static func fetchAppArchiveStatus() -> Single<[AppArchiveStatus]>
}

class ArchiveDataEngine: ArchiveDataEngineDelegate {
    static func fetchAppArchiveStatus() -> Single<[AppArchiveStatus]> {
        Global.log.info("[start] ArchiveDataEngine.fetchAppArchiveStatus")

        return FBArchiveService.getAll()
            .do(onSuccess: { (archives) in
                _ = ArchiveDataEngine.store(archives)
                    .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .andThen(ArchiveDataEngine.issueBitmarkIfNeeded())
                    .subscribe(onCompleted: {
                        Global.log.info("[done] storeAndIssueBitmarkIfNeeded")
                    }, onError: { (error) in
                        Global.log.error(error)
                    })
            })
            .map { (archives) -> [Archive] in
                // Check to clear cache storage
                let numberOfProcessed = archives.filter({ $0.status == AppArchiveStatus.processed.rawValue }).count
                let trackingNumberOfProcessed = Global.current.userDefault?.numberOfProcessedArchives ?? 0

                if trackingNumberOfProcessed < numberOfProcessed {
                    Global.clearCacheStorage()
                    _ = FbmAccountDataEngine.syncMe().subscribe()
                }

                Global.current.userDefault?.numberOfProcessedArchives = numberOfProcessed

                return archives
            }
            .map { (archives) -> [AppArchiveStatus] in
                var appArchiveStatuses = [AppArchiveStatus?]()

                let orderedArchiveStatuses: [ArchiveStatus] = [.processed, .processing, .submitted, .invalid, .created]
                orderedArchiveStatuses.forEach { (orderedArchiveStatus) in
                    appArchiveStatuses.append(archives.appArchiveStatusIfContains(orderedArchiveStatus))
                }

                if UserDefaults.standard.FBArchiveCreatedAt != nil {
                    appArchiveStatuses.append(.requesting)
                }

                return appArchiveStatuses.compactMap { $0 }
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

            return Completable.create { (event) -> Disposable in
                do {
                    let realm = try RealmConfig.currentRealm()
                    let archives = realm.objects(Archive.self)
                        .filter({ !$0.issueBitmark && $0.status == ArchiveStatus.processed.rawValue && $0.contentHash != "" })

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

                                let archiveContentHash = archive.contentHash
                                return Observable.zip(appInfoSingle, eulaSingle)
                                    .map { (appInfo, eula) -> AssetInfo in
                                        return AssetInfo(
                                            registrant: account,
                                            assetName: "", fingerprint: archiveContentHash,
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
                        .subscribe(onError: { (error) in
                            guard !AppError.errorByNetworkConnection(error) else { return }
                            Global.log.error(error)
                        }, onCompleted: {
                            print(Thread.current.threadName)
                            autoreleasepool {
                                do {
                                    try realm.write {
                                        archive.issueBitmark = true
                                    }
                                } catch {
                                    Global.log.error(error)
                                }
                            }
                        })
                }

                    event(.completed)
                } catch {
                    event(.error(error))
                }
                return Disposables.create()
            }
        }
    }
}

extension Array where Element: Archive {
    func appArchiveStatusIfContains(_ status: ArchiveStatus) -> AppArchiveStatus? {
        guard contains(where: { $0.status == status.rawValue }) else {
            return nil
        }

        switch status {
        case .processed:               return .processed
        case .processing, .submitted:  return .processing
        case .created:                 return .created
        case .invalid:
            let sortedInvalidArchiveIDs = self
                .filter { $0.status == ArchiveStatus.invalid.rawValue }
                .sorted { $0.updatedAt > $1.updatedAt }

            guard let latestInvalidArchive = sortedInvalidArchiveIDs.first else {
                return nil
            }
            return .invalid(sortedInvalidArchiveIDs.map { $0.id }, latestInvalidArchive.messageError)
        }
    }
}
