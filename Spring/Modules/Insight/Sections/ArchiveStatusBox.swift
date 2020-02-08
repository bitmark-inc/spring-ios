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

enum AppArchiveStatus {
    case stillWaiting
    case processingData
    case done

    static var currentState: Self {
        if UserDefaults.standard.FBArchiveCreatedAt != nil {
            return .stillWaiting
        }

        let archiveStatus = ArchiveStatus(rawValue: Global.current.userDefault?.latestArchiveStatus ?? "")
        switch archiveStatus {
        case .processed, nil: return .done
        default: return .processingData
        }
    }
}

class ArchiveStatusBox: UIView {

    // MARK: - Properties
    fileprivate lazy var statusLabel = makeStatusLabel()
    fileprivate lazy var descriptionLabel = makeDescriptionLabel()
    fileprivate lazy var controlButton = makeControlButton()

    let disposeBag = DisposeBag()
    var heightConstraint: Constraint!

    var appArchiveStatus: AppArchiveStatus = .done {
        didSet {
            switch appArchiveStatus {
            case .stillWaiting:
                statusLabel.setText(R.string.phrase.dataRequestedWaitingTitle())
                descriptionLabel.setText(R.string.phrase.dataRequestedWaitingDescription())
            case .processingData:
                statusLabel.setText(R.string.phrase.dataProcessingTitle())
                descriptionLabel.setText(R.string.phrase.dataProcessingDescription())
            default:
                break
            }
        }
    }

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
                .inset(UIEdgeInsets(top: Size.dh(18), left: 18, bottom: 0, right: 0))
        }

        controlButton.snp.makeConstraints { (make) in
            make.top.equalTo(statusLabel)
            make.trailing.equalToSuperview().offset(-18)
        }

        descriptionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(statusLabel.snp.bottom).offset(Size.dh(9))
            make.leading.trailing.equalToSuperview()
                .inset(UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18))
        }

        snp.makeConstraints { (make) in
            heightConstraint = make.height.equalTo(descriptionLabel).offset(Size.dh(82)).constraint
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
            font: R.font.atlasGroteskRegular(size: Size.ds(24)),
            colorTheme: .black,
            lineHeight: 1.2)
        return label
    }

    fileprivate func makeDescriptionLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            colorTheme: .black,
            lineHeight: 1.2)
        return label
    }

    fileprivate func makeControlButton() -> Button {
        let button = Button()
        button.setImage(R.image.arrowDown(), for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: Size.dh(36), right: 15)
        return button
    }
}
