//
//  TimeFilterView.swift
//  Spring
//
//  Created by Thuyen Truong on 12/23/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class TimeFilterView: UIView {
    private let filterSegment = FilterSegment(elements: [R.string.localizable.week().localizedUppercase,
                                                         R.string.localizable.year().localizedUppercase,
                                                         R.string.localizable.decade().localizedUppercase
    ])

    weak var timelineDelegate: TimelineDelegate?

    private lazy var previousPeriodButton = makePrevPeriodButton()
    private lazy var nextPeriodButton = makeNextPeriodButton()
    private lazy var periodNameLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 18))
    private lazy var periodDescriptionLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 10))

    let filterChangeSubject = PublishSubject<TimeUnit>()
    let disposeBag = DisposeBag()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)

        periodNameLabel.textAlignment = .center
        periodDescriptionLabel.textAlignment = .center

        flex.direction(.column)
            .padding(13, 18, 34, 18)
            .define { (flex) in
                flex.addItem(filterSegment).height(40)
                flex.addItem().marginTop(18).direction(.row).define { (flex) in
                    flex.addItem(previousPeriodButton)
                    flex.addItem().grow(1).define { (flex) in
                        flex.addItem(periodNameLabel)
                        flex.addItem(periodDescriptionLabel).alignSelf(.stretch).marginTop(9)
                    }
                    flex.addItem(nextPeriodButton)
                }
            }

        bindData()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func bindData() {
        filterSegment.rx.selectedIndex
            .map { (index) -> TimeUnit in
                switch index {
                case 0:     return .week
                case 1:     return .year
                case 2:     return .decade
                default:    return .week
                }
            }
            .bind(to: filterChangeSubject)
            .disposed(by: disposeBag)

        filterChangeSubject.subscribe(onNext: { [weak self] (timeUnit) in
            self?.timelineDelegate?.updateTimeUnit(timeUnit)
        }).disposed(by: disposeBag)

        previousPeriodButton.rx.tap.bind { [weak self] in
            self?.timelineDelegate?.prevPeriod()
        }.disposed(by: disposeBag)

        nextPeriodButton.rx.tap.bind { [weak self] in
            self?.timelineDelegate?.nextPeriod()
        }.disposed(by: disposeBag)
    }

    func bindData(periodName: String, periodDescription: String, distance: Int, limitedDistance: Int) {
        periodNameLabel.text = periodName.localizedUppercase
        periodDescriptionLabel.text = periodDescription
        nextPeriodButton.isEnabled = distance < limitedDistance

        periodNameLabel.flex.markDirty()
        periodNameLabel.flex.layout()
        periodDescriptionLabel.flex.markDirty()
        periodDescriptionLabel.flex.layout()
        flex.layout()
    }
}

extension TimeFilterView {
    fileprivate func makePrevPeriodButton() -> Button {
        let button = Button()
        button.setImage(R.image.previous_period(), for: .normal)
        button.setImage(R.image.disabled_previous_period(), for: .disabled)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 34)
        return button
    }

    fileprivate func makeNextPeriodButton() -> Button {
        let button = Button()
        button.setImage(R.image.next_period()!, for: .normal)
        button.setImage(R.image.disabled_next_period(), for: .disabled)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 34, bottom: 10, right: 0)
        button.isEnabled = false
        return button
    }
}
