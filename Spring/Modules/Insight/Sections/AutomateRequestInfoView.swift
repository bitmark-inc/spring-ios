//
//  AutomateRequestInfoView.swift
//  Spring
//
//  Created by Thuyen Truong on 3/17/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class AutomateRequestInfoView: UIView {

    // MARK: - Properties
    lazy var descriptionLabel = makeDescriptionLabel()
    lazy var requestTimelabel = makeRequestTimeLabel()
    lazy var loadingIndicator = makeLoadingIndicator()

    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    let disposeBag = DisposeBag()

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.define({ (flex) in
            flex.padding(0, 18, 30, 48)
                .define { (flex) in
                    flex.addItem(descriptionLabel)
                    flex.addItem(requestTimelabel).marginTop(10)

                    flex.addItem(loadingIndicator)
                        .marginTop(30)
                        .alignSelf(.center)
                }
        })

        bindInfo()
    }

    func bindInfo() {
        GetYourData.standard.requestedAtRelay
            .subscribe(onNext: { [weak self] (fbArchiveCreatedAt) in
                guard let self = self else { return }
                if let fbArchiveCreatedAt = fbArchiveCreatedAt {
                    self.requestTimelabel.setText(R.string.phrase.browseWaitingArchiveDescriptionTime(
                        fbArchiveCreatedAt.string(withFormat: Constant.TimeFormat.archive)))
                } else {
                    self.requestTimelabel.setText(nil)
                }

                self.requestTimelabel.flex.markDirty()
                self.flex.layout()

            })
            .disposed(by: disposeBag)

        GetYourData.standard.runningState
            .map { $0 == .loading }
            .bind(to: loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension AutomateRequestInfoView {
    fileprivate func makeDescriptionLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            text: R.string.phrase.browseWaitingArchiveDescription(),
            font: R.font.atlasGroteskLight(size: 18),
            colorTheme: .black, lineHeight: 1.27)
        return label
    }

    fileprivate func makeRequestTimeLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            font: R.font.atlasGroteskThinItalic(size: 15),
            colorTheme: .black, lineHeight: 1.27)
        return label
    }

    fileprivate func makeLoadingIndicator() -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView()
        if #available(iOS 13.0, *) {
            indicator.style = .large
        } else {
            indicator.style = .gray
        }
        indicator.color = UIColor(hexString: "#000", transparency: 0.4)!
        return indicator
    }
}
