//
//  Button.swift
//  Spring
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class Button: UIButton {

    let disposeBag = DisposeBag()

    required init() {
        super.init(frame: .zero)
        setupViews()
    }

    convenience init(title: String) {
        self.init()
        setTitle(title, for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() { }
}

extension Button {
    func apply(title: String, font: UIFont?, colorTheme: ColorTheme) {
        self.setTitle(title, for: .normal)
        self.titleLabel?.font = font

        switch colorTheme {
        case .black:
            themeService.rx
                .bind({ $0.blackButtonTextColor }, to: rx.titleColor(for: .normal))
                .disposed(by: disposeBag)

        case .white:
            themeService.rx
                .bind({ $0.lightButtonTextColor }, to: rx.titleColor(for: .normal))
                .bind({ $0.lightButtonTextColor.withAlphaComponent(0.5) }, to: rx.titleColor(for: .disabled))
                .disposed(by: disposeBag)

        case .cognac:
            themeService.rx
                .bind({ $0.themeColor }, to: rx.titleColor(for: .normal))
                .bind({ $0.themeColor.withAlphaComponent(0.5) }, to: rx.titleColor(for: .disabled))
                .disposed(by: disposeBag)

        default:
            themeService.rx
                .bind({ $0.blackButtonTextColor }, to: rx.titleColor(for: .normal))
                .disposed(by: disposeBag)
        }
    }

    func applyUnderlinedLight(title: String, font: UIFont?) {
        self.setAttributedTitle(title.asLink(), for: .normal)
        self.titleLabel?.font = font

        themeService.rx
            .bind({ $0.lightButtonTextColor }, to: rx.titleColor(for: .normal))
            .disposed(by: disposeBag)
    }
}
