//
//  ReadingTextView.swift
//  Spring
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class ReadingTextView: UITextView {

    let disposeBag = DisposeBag()

    public convenience init(text: String) {
        self.init(frame: .zero)
        setupView()

        self.text = text
    }

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func setupView() {
        backgroundColor = .clear
        font = Avenir.size(24)
        isUserInteractionEnabled = true
        isEditable = false
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
    }

    func apply(colorTheme: ColorTheme) {
        switch colorTheme {
        case .black:
            themeService.rx
                .bind({ $0.blackTextColor }, to: rx.textColor)
                .disposed(by: disposeBag)

        case .tundora:
            themeService.rx
                .bind({ $0.tundoraTextColor }, to: rx.textColor)
                .disposed(by: disposeBag)

        default:
            themeService.rx
                .bind({ $0.blackTextColor }, to: rx.textColor)
                .disposed(by: disposeBag)
        }
    }
}
