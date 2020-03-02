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
    var submitEnabledDriver: Driver<Bool>

    override init() {
        submitEnabledDriver = BehaviorRelay.combineLatest(archiveZipURLRelay, downloadableURLRelay)
            .map { $0 != nil || $1 != nil }
            .asDriver(onErrorJustReturn: false)

        super.init()
    }
}
