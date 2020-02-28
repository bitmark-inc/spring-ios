//
//  TextField.swift
//  Spring
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class TextField: UITextField {

    let disposeBag = DisposeBag()

}

extension TextField {
    func apply(placeholder: String? = nil, font: UIFont?, colorTheme: ColorTheme) {
        self.placeholder = placeholder
        self.font = font

        switch colorTheme {
        case .black:
            themeService.rx
                .bind({ $0.blackTextColor }, to: rx.textColor)
                .bind({ $0.textFieldPlaceholderColor }, to: rx.placeholderColor)
                .disposed(by: disposeBag)
        default:
            themeService.rx
                .bind({ $0.blackTextColor }, to: rx.textColor)
                .disposed(by: disposeBag)
        }
    }
}
