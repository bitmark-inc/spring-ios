//
//  SubmitButton.swift
//  Spring
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import FlexLayout

class SubmitButton: Button {

    override func setupViews() {
        super.setupViews()

        titleLabel?.font = R.font.atlasGroteskLight(size: 18)
        flex.height(50)
    }
}

extension SubmitButton {
    func applyTheme(colorTheme: ColorTheme) {
        switch colorTheme {
        case .mercury:
            themeService.rx
                .bind({ UIImage(color: $0.themeMercuryColor, size: CGSize(width: 1, height: 1)) }, to: rx.backgroundImage(for: .normal))
                .bind({ $0.blackTextColor }, to: rx.titleColor(for: .normal))
                .disposed(by: disposeBag)

        case .indianKhaki:
            themeService.rx
                .bind({ UIImage(color: $0.themeIndianKhakiColor, size: CGSize(width: 1, height: 1)) }, to: rx.backgroundImage(for: .normal))
                .bind({ $0.blackTextColor }, to: rx.titleColor(for: .normal))
                .disposed(by: disposeBag)

        default:
            themeService.rx
                .bind({ UIImage(color: $0.themeColor, size: CGSize(width: 1, height: 1)) }, to: rx.backgroundImage(for: .normal))
                .bind({ UIImage(color: $0.themeMercuryColor, size: CGSize(width: 1, height: 1)) }, to: rx.backgroundImage(for: .disabled))
                .bind({ $0.lightButtonTextColor }, to: rx.titleColor(for: .normal))
                .bind({ $0.blackButtonTextColor }, to: rx.titleColor(for: .disabled))
                .disposed(by: disposeBag)
        }
    }
}
