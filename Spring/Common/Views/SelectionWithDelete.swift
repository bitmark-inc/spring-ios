//
//  SelectionWithDelete.swift
//  OurBeat
//
//  Created by Thuyen Truong on 2/19/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import RxSwift
import RxCocoa
import UIKit

class SelectionWithDelete: UIView {

    // MARK: - Properties
    lazy var selectionButton = makeSelectionButton()
    lazy var deleteButton = makeDeleteButton()

    var placeholder: String! {
        didSet {
            selectionButton.setTitle(placeholder, for: .normal)
        }
    }

    let disposeBag = DisposeBag()

    init(placeholder: String = "") {
        super.init(frame: CGRect.zero)
        self.placeholder = placeholder
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        backgroundColor = themeService.attrs.buttonBackground

        flex.direction(.row).define { (flex) in
            flex.addItem(selectionButton).grow(1)
            flex.addItem(deleteButton).width(0)
        }
    }

    func apply(font: UIFont?, colorTheme: ColorTheme) {
        selectionButton.titleLabel?.font = font
        backgroundColor = colorTheme.color
    }

    fileprivate func makeSelectionButton() -> Button {
        let button = Button()
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 13, bottom: 7, right: 13)
        button.backgroundColor = .clear
        button.setTitle(placeholder, for: .normal)
        return button
    }

    fileprivate func makeDeleteButton() -> UIButton {
        let button = UIButton()
        button.setImage(R.image.cancelField(), for: .normal)
        button.backgroundColor = .clear
        return button
    }
}

extension Reactive where Base: SelectionWithDelete {
    var text: Binder<String?> {
        return Binder(base) { view, text in
            if let text = text {
                view.selectionButton.setTitle(text, for: .normal)
                view.deleteButton.flex.width(43)
            } else {
                view.selectionButton.setTitle(view.placeholder, for: .normal)
                view.deleteButton.flex.width(0)
            }

            view.deleteButton.flex.markDirty()
            view.flex.layout()
        }
    }
}
