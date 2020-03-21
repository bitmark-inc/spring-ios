//
//  UpdateYourDataViewModel.swift
//  Spring
//
//  Created by Thuyen Truong on 3/20/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

class UpdateYourDataViewModel: ViewModel {

    // MARK: - Properties
    static var AccountServiceBase: AccountServiceDelegate.Type = AccountService.self

    // MARK: - Inputs
    var archiveZipRelay = BehaviorRelay<(url: URL, size: Int64)?>(value: nil)
    var downloadableURLRelay = BehaviorRelay<URL?>(value: nil)

    // MARK: - Outputs
    let signUpResultSubject = PublishSubject<Event<Never>>()
    let submitArchiveDataResultSubject = PublishSubject<Event<Never>>()
    let realmFbmAccountResultsRelay = BehaviorRelay<Results<FbmAccount>?>(value: nil)

    override init() {
        super.init()

        realmFbmAccountResultsRelay.accept(FbmAccountDataEngine.fetchResultsMe())
    }

    func submitArchiveData() {
        if let archiveZip = archiveZipRelay.value {
            FBArchiveService.getPresignedURL(with: archiveZip.size)
                .subscribe(onSuccess: { [weak self] (presignedURL) in
                    guard let self = self else { return }
                    FBArchiveService.submitByFile(archiveZip.url, with: presignedURL)
                    self.submitArchiveDataResultSubject.onNext(Event.completed)
                }, onError: { [weak self] (error) in
                    self?.submitArchiveDataResultSubject.onNext(Event.error(error))
                })
                .disposed(by: disposeBag)

        } else if let downloadableURL = downloadableURLRelay.value {
            loadingState.onNext(.loading)
            FBArchiveService.submitByURL(downloadableURL)
                .asObservable()
                .materialize().bind { [weak self] in
                    self?.submitArchiveDataResultSubject.onNext($0)
                }
                .disposed(by: disposeBag)
        }
    }

    func update(isAutomate: Bool? = nil) -> Completable {
        guard let isAutomate = isAutomate else {
            return Completable.empty()
        }

        return FbmAccountDataEngine.update(isAutomate: isAutomate).asCompletable()
    }
}
