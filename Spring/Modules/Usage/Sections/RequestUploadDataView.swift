//
//  RequestUploadDataView.swift
//  Spring
//
//  Created by Thuyen Truong on 2/26/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class RequestUploadDataView: UIView {

    // MARK: - Properties
    fileprivate lazy var titleLabel = makeTitleLabel()
    fileprivate lazy var descriptionLabel = makeDescriptionLabel()
    fileprivate lazy var uploadDataButton = makeUploadDataButton()
    fileprivate lazy var exclamationIcon = ImageView(image: R.image.exclamationIcon())

    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    let disposeBag = DisposeBag()

    var actionTitle: String = "" {
        didSet {
            uploadDataButton.setTitle(actionTitle, for: .normal)
        }
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column)
            .padding(30, 18, 18, 18)
            .define { (flex) in
                flex.addItem(titleLabel)
                flex.addItem(descriptionLabel).marginTop(7)
                flex.addItem(uploadDataButton).marginTop(20)
            }
    }

    func setProperties(section: Section, container: UsageViewController) {
        guard section == .requestUploadDataInUsage else { return }
        weak var container = container

        titleLabel.setText(R.string.phrase.requestUploadDataUsageTitle().localizedUppercase)
        descriptionLabel.setText(R.string.phrase.requestUploadDataUsageDescription())
        uploadDataButton.setTitleColor(ColorTheme.cognac.color, for: .normal)

        uploadDataButton.rx.tap.bind { [weak container] in
            container?.moveToViewProgressScreen()
        }.disposed(by: disposeBag)
    }

    func setProperties(section: Section, container: InsightViewController) {
        guard section == .requestUploadDataInInsights else { return }
        weak var container = container

        titleLabel.setText(R.string.phrase.requestUploadDataInsightsTitle().localizedUppercase)
        descriptionLabel.setText(R.string.phrase.requestUploadDataInsightsDescription())
        uploadDataButton.setTitleColor(ColorTheme.internationalKleinBlue.color, for: .normal)

        uploadDataButton.rx.tap.bind { [weak container] in
            container?.gotoUploadDataScreen()
        }.disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension RequestUploadDataView {
    fileprivate func makeTitleLabel() -> Label {
        let label = Label()
        label.apply(
            font: R.font.domaineSansTextLight(size: 22),
            colorTheme: .black, lineHeight: 1.05)
        return label
    }

    fileprivate func makeDescriptionLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            font: R.font.atlasGroteskLight(size: 16),
            colorTheme: .black, lineHeight: 1.25)
        return label
    }

    fileprivate func makeUploadDataButton() -> Button {
        let button = Button()
        button.contentHorizontalAlignment = .leading
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        button.titleLabel?.font = R.font.atlasGroteskLight(size: 16)
        return button
    }
}
