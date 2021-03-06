//
//  ProgressHUD.swift
//  Spring
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SVProgressHUD

let loadingState = PublishSubject<LoadState>()

extension Reactive where Base: SVProgressHUD {
    static var state: Binder<LoadState> {
        return Binder(UIApplication.shared) { _, state in
            switch state {
            case .loading:
                SVProgressHUD.show()
            case .success:
                SVProgressHUD.showSuccess(withStatus: R.string.localizable.success())
            case .tickSuccess:
                SVProgressHUD.showSuccess(withStatus: nil)
            case .failed:
                SVProgressHUD.showError(withStatus: nil)
            case .hide:
                SVProgressHUD.dismiss()
            }
        }
    }
}

enum LoadState {
    case loading
    case success
    case failed
    case hide
    case tickSuccess
}
