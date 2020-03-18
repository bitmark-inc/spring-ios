//
//  GetYourData.swift
//  Spring
//
//  Created by Thuyen Truong on 3/17/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum GetYourDataOption: String {
    case automate
    case manual
    case undefined
}

class GetYourData {
    static var standard = GetYourData()

    let optionRelay = BehaviorRelay<GetYourDataOption>(value: .undefined)
    let getCategoriesState = BehaviorRelay<LoadState>(value: .hide)
    lazy var requestedAtRelay: BehaviorRelay<Date?> = {
        BehaviorRelay<Date?>(value: UserDefaults.standard.FBArchiveCreatedAt)
    }()
    let runningState = BehaviorRelay<LoadState>(value: .hide)
}
