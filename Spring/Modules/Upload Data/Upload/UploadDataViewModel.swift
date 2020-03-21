//
//  UploadDataViewModel.swift
//  Spring
//
//  Created by Thuyen Truong on 2/26/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class UploadDataViewModel: ViewModel {

    // MARK: - Properties
    static var AccountServiceBase: AccountServiceDelegate.Type = AccountService.self

    // MARK: - Inputs
    var archiveZipRelay = BehaviorRelay<(url: URL, size: Int64)?>(value: nil)
    var downloadableURLRelay = BehaviorRelay<URL?>(value: nil)

    // MARK: - Outputs
    let signUpResultSubject = PublishSubject<Event<Never>>()
    let submitArchiveDataResultSubject = PublishSubject<Event<Never>>()

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

    func signUp(isAutomate: Bool) -> Completable {
        return Self.AccountServiceBase.rxCreateAndSetupNewAccountIfNotExist()
            .andThen(FbmAccountDataEngine.createOrUpdate(isAutomate: isAutomate))
            .flatMapCompletable{ (_) -> Completable in
                GetYourData.standard.optionRelay.accept(isAutomate ? .automate : .manual)
                return Completable.empty()
            }
            .catchError { (error) -> Completable in
                if let error = error as? ServerAPIError, error.code == .AccountHasTaken {
                    return Completable.empty()
                }

                return Completable.error(error)
            }
    }
}
