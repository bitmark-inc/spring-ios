//
//  ArchiveStatusBox.swift
//  Spring
//
//  Created by Thuyen Truong on 2/5/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import SnapKit

enum AppArchiveStatus: String {
    case uploading
    case processing
    case processed
    case none

    static var localLatestArchiveStatus: AppArchiveStatus {
        return Global.current.userDefault?.latestAppArchiveStatus ?? .none
    }

    static var currentState = BehaviorRelay<AppArchiveStatus?>(value: localLatestArchiveStatus)
}

class ArchiveStatusBox: UIView {

    // MARK: - Properties
    fileprivate lazy var statusLabel = makeStatusLabel()
    fileprivate lazy var descriptionLabel = makeDescriptionLabel()
    fileprivate lazy var controlButton = makeControlButton()

    let disposeBag = DisposeBag()
    var heightConstraint: Constraint!

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white
        layer.shadowOpacity = 0.2
        layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor

        addSubview(statusLabel)
        addSubview(controlButton)
        addSubview(descriptionLabel)

        statusLabel.snp.makeConstraints { (make) in
            make.leading.top.equalToSuperview()
                .inset(UIEdgeInsets(top: 18, left: 18, bottom: 0, right: 0))
        }

        controlButton.snp.makeConstraints { (make) in
            make.top.equalTo(statusLabel)
            make.trailing.equalToSuperview().offset(-18)
        }

        descriptionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(statusLabel.snp.bottom).offset(9)
            make.leading.trailing.equalToSuperview()
                .inset(UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18))
        }

        snp.makeConstraints { (make) in
            heightConstraint = make.height.equalTo(descriptionLabel).offset(82).constraint
        }

        controlButton.rx.tap.bind { [weak self] in
            self?.down()
        }.disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    fileprivate func down() {
        UIView.animate(withDuration: 0.35, animations: {
            self.heightConstraint.update(offset: -self.descriptionLabel.height)
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }, completion: { (_) in
            self.removeFromSuperview()
        })
    }
}

extension ArchiveStatusBox {
    fileprivate func makeStatusLabel() -> Label {
        let label = Label()
        label.apply(
            font: R.font.atlasGroteskRegular(size: 24),
            colorTheme: .black,
            lineHeight: 1.2)
        return label
    }

    fileprivate func makeDescriptionLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            font: R.font.atlasGroteskLight(size: 18),
            colorTheme: .black,
            lineHeight: 1.2)
        return label
    }

    fileprivate func makeControlButton() -> Button {
        let button = Button()
        button.setImage(R.image.arrowDown(), for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 36, right: 15)
        return button
    }
}
