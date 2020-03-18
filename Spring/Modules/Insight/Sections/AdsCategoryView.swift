//
//  AdsCategoryView.swift
//  Spring
//
//  Created by Thuyen Truong on 1/9/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class AdsCategoryView: UIView {

    // MARK: - Properties
    lazy var headerLabel = makeHeaderLabel()
    lazy var descriptionLabel = makeDescriptionLabel()
    lazy var adsCategoryInfoView = makeAdsCategoryInfoView()
    lazy var loadingIndicator = makeLoadingIndicator()
    lazy var space = UIView()

    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    let disposeBag = DisposeBag()

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.define({ (flex) in
            flex.padding(30, 18, 30, 48)
                .define { (flex) in
                    flex.addItem(headerLabel)
                    flex.addItem(descriptionLabel).marginTop(7)

                    flex.addItem(loadingIndicator)
                        .top(150).position(.absolute)
                        .alignSelf(.center)
                    flex.addItem(space).height(30)

                    flex.addItem(adsCategoryInfoView)
                        .padding(10, 18, 0, 40)
                        .maxWidth(100%)
                }
        })
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(container: UsageViewController) {
        weak var container = container

        GetYourData.standard.getCategoriesState
            .subscribe(onNext: { [weak self] (state) in
                guard let self = self else { return }
                switch state {
                case .loading:  self.loadingIndicator.startAnimating()
                default:        self.loadingIndicator.stopAnimating()
                }
            })
            .disposed(by: disposeBag)

        container?.thisViewModel.realmAdsCategoriesResultsRelay
            .filterNil()
            .observeObject()
            .map { $0?.valueObject() }
            .filterNil()
            .subscribe(onNext: { [weak self] (adsCategories) in
                self?.fillData(adsCategories: adsCategories)
            })
            .disposed(by: disposeBag)
    }

    fileprivate func fillData(adsCategories: [String]) {
        adsCategoryInfoView.removeSubviews()
        if adsCategories.count > 0 {
            for adsCategory in adsCategories {
                adsCategoryInfoView.flex.define { (flex) in
                    flex.addItem(makeAdsCategoryRow(adsCategory: adsCategory)).width(100%).marginTop(16)
                }
            }
        } else {
            adsCategoryInfoView.flex.define { (flex) in
                flex.addItem(makeNoDataView())
            }
        }

        space.flex.height(0)

        adsCategoryInfoView.flex.layout()
        containerLayoutDelegate?.layout()
    }
}

extension AdsCategoryView {
    fileprivate func makeHeaderLabel() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.adsCategoryHeader(),
            font: R.font.domaineSansTextLight(size: 22),
            colorTheme: .black, lineHeight: 1.056)
        return label
    }

    fileprivate func makeDescriptionLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            text: R.string.phrase.adsCategoryDescription(),
            font: R.font.atlasGroteskLight(size: 16),
            colorTheme: .black, lineHeight: 1.27)
        return label
    }

    fileprivate func makeAdsCategoryInfoView() -> UIView {
        return UIView()
    }

    fileprivate func makeAdsCategoryRow(adsCategory: String) -> UIView {
        let view = UIView()

        let markView = UIView()
        markView.backgroundColor = ColorTheme.cognac.color

        let adsCategoryLabel = Label()
        adsCategoryLabel.numberOfLines = 0
        adsCategoryLabel.apply(
            text: adsCategory, font: R.font.atlasGroteskLight(size: 14),
            colorTheme: .black, lineHeight: 1.236)

        view.flex
            .direction(.row)
            .define { (flex) in
                flex.addItem(markView).width(2).height(100%)
                flex.addItem(adsCategoryLabel).marginLeft(7).width(100%)
            }

        return view
    }

    fileprivate func makeNoDataView() -> Label {
        let label = Label()
        label.apply(text: R.string.localizable.noDataAvailable(),
                    font: R.font.atlasGroteskLight(size: 14),
                    colorTheme: .black,
                    lineHeight: 1.056)
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
