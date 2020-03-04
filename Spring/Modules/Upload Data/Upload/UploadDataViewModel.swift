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

    // MARK: - Inputs
    var archiveZipURLRelay = BehaviorRelay<URL?>(value: nil)
    var downloadableURLRelay = BehaviorRelay<URL?>(value: nil)

    // MARK: - Outputs
    let submitArchiveDataResultSubject = PublishSubject<Event<Never>>()

    func submitArchiveData() {
        if let archiveZipURL = archiveZipURLRelay.value {
            FBArchiveService.submitByFile(archiveZipURL)
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
}
