//
//  UsageBadgeView.swift
//  Spring
//
//  Created by Thuyen Truong on 12/23/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class UsageBadgeView: UIView {

    let disposeBag = DisposeBag()

    private lazy var postDataBadgeView: DataBadgeView = {
        let u = DataBadgeView()
        u.descriptionLabel.text = R.string.localizable.pluralPost().localizedUppercase
        return u
    }()

    private lazy var reactionsDataBadgeView: DataBadgeView = {
        let u = DataBadgeView()
        u.descriptionLabel.text = R.string.localizable.pluralReaction().localizedUppercase
        return u
    }()

    private lazy var messagesDataBadgeView: DataBadgeView = {
        let u = DataBadgeView()
        u.descriptionLabel.text = R.string.localizable.pluralMessage().localizedUppercase
        return u
    }()

    let emptyPercentage = "--"

    lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.row)
            .paddingLeft(18).paddingRight(18).marginBottom(30)
            .justifyContent(.spaceAround)
            .define { (flex) in
                flex.addItem(postDataBadgeView)
                flex.addItem(reactionsDataBadgeView)
            }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(container: UsageViewController) {
        weak var container = container
        var postUsageObserver: Disposable?
        var reactionUsageObserver: Disposable?

        container?.thisViewModel.realmPostUsageRelay
            .subscribe(onNext: { [weak self] (usage) in
                guard let self = self, let container = container else { return }

                if usage != nil {
                    postUsageObserver?.dispose()
                    postUsageObserver = container.postUsageObservable
                        .map { $0.diffFromPrevious }
                        .subscribe(onNext: { [weak self] (postBadge) in
                            self?.fillData(with: (badge: postBadge, section: .post))
                        })

                    postUsageObserver?
                        .disposed(by: self.disposeBag)

                } else {
                    postUsageObserver?.dispose()
                    self.fillData(with: (badge: nil, section: .post))
                }
            })
            .disposed(by: disposeBag)

        container?.thisViewModel.realmReactionUsageRelay
            .subscribe(onNext: { [weak self] (usage) in
                guard let self = self, let container = container else { return }
                if usage != nil {
                    reactionUsageObserver?.dispose()
                    reactionUsageObserver = container.reactionUsageObservable
                        .map { $0.diffFromPrevious }
                        .subscribe(onNext: { [weak self] (reactionBadge) in
                            self?.fillData(with: (badge: reactionBadge, section: .reaction))
                        })

                    reactionUsageObserver?
                        .disposed(by: self.disposeBag)
                } else {
                    postUsageObserver?.dispose()
                    self.fillData(with: (badge: nil, section: .reaction))
                }
            })
            .disposed(by: disposeBag)
    }

    func fillData(with data: (badge: Double?, section: Section)) {
        let badge = data.badge
        switch data.section {
        case .post:
            postDataBadgeView.updownImageView.image = getUpDownImageView(with: badge)
            postDataBadgeView.percentageLabel.text = precentageText(with: badge)
            postDataBadgeView.updateValue(with: badge)

        case .reaction:
            reactionsDataBadgeView.updownImageView.image = getUpDownImageView(with: badge)
            reactionsDataBadgeView.percentageLabel.text = precentageText(with: badge)
            reactionsDataBadgeView.updateValue(with: badge)

        case .messages:
            messagesDataBadgeView.updownImageView.image = getUpDownImageView(with: badge)
            messagesDataBadgeView.percentageLabel.text = precentageText(with: badge)
            messagesDataBadgeView.updateValue(with: badge)

        default:
            break
        }
    }

    fileprivate func getUpDownImageView(with badge: Double?) -> UIImage? {
        guard let badge = badge else { return nil }
        if badge > 0 {
            return R.image.usage_up()!
        } else if badge == 0 {
            return R.image.usageEqual()
        } else {
            return R.image.usage_down()!
        }
    }

    fileprivate func precentageText(with badge: Double?) -> String {
        guard let badge = badge else { return emptyPercentage }
        let number = NSNumber(value: abs(Int(badge * 100)))
        guard let formattedNumber = numberFormatter.string(from: number) else { return "" }
        return "  \(formattedNumber)%"
    }
}
