//
//  TrackingRequestState.swift
//  Spring
//
//  Created by Thuyen Truong on 3/19/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class TrackingRequestState {

    static var standard = TrackingRequestState()

    let syncPostsState      = BehaviorRelay<LoadState>(value: .hide)
    let syncReactionsState  = BehaviorRelay<LoadState>(value: .hide)
    let syncMediaState      = BehaviorRelay<LoadState>(value: .hide)
}
