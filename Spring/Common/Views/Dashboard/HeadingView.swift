//
//  HeadingView.swift
//  Spring
//
//  Created by Thuyen Truong on 12/23/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class HeadingView: UIView {

    // MARK: - Properties
    lazy var titleLabel = Label.create(withFont: R.font.domaineSansTextLight(size: 36))
    lazy var subTitleLabel = Label.create(withFont: R.font.domaineSansTextLight(size: 18))
    let disposeBag = DisposeBag()

    var subTitle = "" {
        didSet {
            subTitleLabel.text = subTitle
            flex.layout()
        }
    }

    func setHeading(title: String, color: UIColor?) {
        titleLabel.text = title
        titleLabel.textColor = color
        flex.layout()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        flex
            .padding(30, 18, 30, 18)
            .direction(.column).define { (flex) in
                flex.alignItems(.stretch)

                flex.addItem().direction(.row).define { (flex) in
                    flex.alignItems(.start)
                    flex.addItem(titleLabel)
                }

                flex.addItem(subTitleLabel).marginTop(0)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
