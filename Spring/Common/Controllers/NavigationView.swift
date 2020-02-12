//
//  NavigationView.swift
//  Spring
//
//  Created by thuyentruong on 11/27/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

protocol BackNavigator {
    func makeBlackBackItem() -> Button
    func makeLightBackItem() -> Button
}

extension BackNavigator where Self: ViewController {
    func makeBlackBackItem() -> Button {
        let backButton = Button()
        backButton.apply(
            title: R.string.localizable.backNavigator().localizedUppercase,
            font: R.font.avenir(size: Size.ds(14)),
            colorTheme: .black)
        backButton.contentHorizontalAlignment = .left

        backButton.rx.tap.bind { [weak self] in
            self?.tapToBack()
        }.disposed(by: disposeBag)

        return backButton
    }

    func makeLightBackItem() -> Button {
        let backButton = Button()
        backButton.apply(
            title: R.string.localizable.backNavigator().localizedUppercase,
            font: R.font.avenir(size: Size.ds(14)),
            colorTheme: .white)
        backButton.contentHorizontalAlignment = .left

        backButton.rx.tap.bind { [weak self] in
            self?.tapToBack()
        }.disposed(by: disposeBag)

        return backButton
    }

    func tapToBack() {
        Navigator.default.pop(sender: self)
    }
}
