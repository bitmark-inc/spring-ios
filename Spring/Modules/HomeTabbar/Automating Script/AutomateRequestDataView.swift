//
//  AutomateRequestDataView.swift
//  Spring
//
//  Created by Thuyen Truong on 3/17/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import WebKit

class AutomateRequestDataView: UIView {

    // MARK: - Properties
    lazy var closeButton = makeCloseButton()
    fileprivate lazy var guideTextLabel = makeGuideTextLabel()
    lazy var webView = makeWebView()

    fileprivate let disposeBag = DisposeBag()

    var guideText: String? {
        didSet {
            guideTextLabel.setText(guideText)
        }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)

        cornerRadius = 18

        addSubview(closeButton)
        addSubview(guideTextLabel)
        addSubview(webView)

        guideTextLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(41)
            make.centerX.equalToSuperview()
        }

        closeButton.snp.makeConstraints { (make) in
            make.top.equalTo(guideTextLabel).offset(-10)
            make.leading.equalToSuperview().offset(18)
        }

        webView.snp.makeConstraints { (make) in
            make.top.equalTo(guideTextLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
     }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension AutomateRequestDataView {
    fileprivate func makeCloseButton() -> Button {
        let button = Button()
        button.setImage(R.image.closeBox(), for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return button
    }

    fileprivate func makeGuideTextLabel() -> Label {
        let label = Label()
        label.apply(
            font: R.font.atlasGroteskRegular(size: 18),
            colorTheme: .white,
            lineHeight: 1.2)
        return label
    }

    func makeWebView() -> WKWebView {
        return WKWebView()
    }
}
