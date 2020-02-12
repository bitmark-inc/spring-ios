//
//  FbmAccountDataEngine.swift
//  Spring
//
//  Created by thuyentruong on 11/27/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

protocol FbmAccountDataEngineDelegate {
    static func fetchCurrentFbmAccount() -> Single<FbmAccount>
    static func fetchLocalFbmAccount() -> Single<FbmAccount?>
    static func fetchLatestFbmAccount() -> Single<FbmAccount>
    static func create() -> Single<FbmAccount>
    static func fetchOverallArchiveStatus() -> Single<ArchiveStatus?>
}

class FbmAccountDataEngine: FbmAccountDataEngineDelegate {
    static func fetchCurrentFbmAccount() -> Single<FbmAccount> {
        Global.log.info("[start] FbmAccountDataEngine.rx.fetchCurrentFbmAccount")

        return Single<FbmAccount>.create { (event) -> Disposable in
            guard let number = Global.current.account?.getAccountNumber() else {
                return Disposables.create()
            }

            autoreleasepool {
                do {
                    guard Thread.current.isMainThread else {
                        throw AppError.incorrectThread
                    }
                    
                    let realm = try RealmConfig.currentRealm()
                    if let fbmAccount = realm.object(ofType: FbmAccount.self, forPrimaryKey: number) {
                        event(.success(fbmAccount))
                    } else {
                        _ = FbmAccountService.getMe()
                            .flatMapCompletable { Storage.store($0) }
                            .observeOn(MainScheduler.instance)
                            .subscribe(onCompleted: {
                                guard let fbmAccount = realm.object(ofType: FbmAccount.self, forPrimaryKey: number)
                                    else {
                                        Global.log.error(AppError.incorrectEmptyRealmObject)
                                        return
                                }
                                
                                event(.success(fbmAccount))
                            }, onError: { (error) in
                                event(.error(error))
                            })
                    }
                } catch {
                    event(.error(error))
                }
            }

            return Disposables.create()
        }
    }

    static func fetchLocalFbmAccount() -> Single<FbmAccount?> {
        return Single<FbmAccount?>.create { (event) -> Disposable in
            guard let number = Global.current.account?.getAccountNumber() else {
                return Disposables.create()
            }

            autoreleasepool {
                do {
                    let realm = try RealmConfig.currentRealm()
                    event(.success(realm.object(ofType: FbmAccount.self, forPrimaryKey: number)))
                } catch {
                    event(.error(error))
                }
            }

            return Disposables.create()
        }
    }

    static func fetchLatestFbmAccount() -> Single<FbmAccount> {
        Global.log.info("[start] FbmAccountDataEngine.rx.fetchLatestFbmAccount")

       return Single<FbmAccount>.create { (event) -> Disposable in
           guard let number = Global.current.account?.getAccountNumber() else {
               return Disposables.create()
           }

            autoreleasepool {
                do {
                    guard Thread.current.isMainThread else { throw AppError.incorrectThread }
                    let realm = try RealmConfig.currentRealm()

                   _ = FbmAccountService.getMe()
                       .flatMapCompletable { Storage.store($0) }
                       .observeOn(MainScheduler.instance)
                       .subscribe(onCompleted: {
                           guard let fbmAccount = realm.object(ofType: FbmAccount.self, forPrimaryKey: number)
                               else {
                                   Global.log.error(AppError.incorrectEmptyRealmObject)
                                   return
                           }

                           event(.success(fbmAccount))
                       }, onError: { (error) in
                            if let fbmAccount = realm.object(ofType: FbmAccount.self, forPrimaryKey: number) {
                                event(.success(fbmAccount))

                                // sends error if error is not networkConnection or requireUpdateVersion
                                guard !AppError.errorByNetworkConnection(error) else { return }
                                if let error = error as? ServerAPIError {
                                    switch error.code {
                                    case .RequireUpdateVersion : return
                                    default: break
                                    }
                                }

                                Global.log.error(error)
                            } else {
                                event(.error(error))
                            }
                       })
                } catch {
                    event(.error(error))
                }
            }

            return Disposables.create()
       }
    }

    static func create() -> Single<FbmAccount> {
        fetchLocalFbmAccount()
            .flatMap { (fbmAccount) in
                guard let fbmAccount = fbmAccount else {
                    return FbmAccountService.create(metadata: [:])
                }

                return Single.just(fbmAccount)
            }
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
