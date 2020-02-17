//
//  SectionHeadingView.swift
//  Spring
//
//  Created by Thuyen Truong on 12/23/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class SectionHeadingView: UIView {

    // MARK: - Properties
    private let countLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 24))
    private let actionDescriptionLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 10))

    var section: Section = .post
    let disposeBag = DisposeBag()

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column).define { (flex) in
            flex.addItem().direction(.row).define { (flex) in
                flex.alignItems(.start).marginTop(30)
                flex.addItem(countLabel)
                flex.addItem(actionDescriptionLabel).marginLeft(7)
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(section: Section, container: UsageViewController) {
        weak var container = container
        self.section = section
        var dataObserver: Disposable? // stop observing old-data

        switch section {
        case .post:
            container?.thisViewModel.realmPostUsageRelay
                .subscribe(onNext: { [weak self] (usage) in
                    guard let self = self, let container = container else { return }
                    if usage != nil {
                        dataObserver?.dispose()
                        dataObserver = container.postUsageObservable
                            .map { $0.quantity }
                            .subscribe(onNext: { [weak self] in
                                self?.fillData(
                                    countText: R.string.localizable.numberOfPosts($0.commaRepresentation),
                                    actionDescriptionText: R.string.localizable.you_made())
                            })
                        dataObserver?.disposed(by: self.disposeBag)
                    } else {
                        dataObserver?.dispose()
                        self.fillData(
                            countText: R.string.localizable.numberOfPosts("0"),
                            actionDescriptionText: R.string.localizable.you_made())
                    }
                })
                .disposed(by: disposeBag)

        case .reaction:
            container?.thisViewModel.realmReactionUsageRelay
                .subscribe(onNext: { [weak self] (usage) in
                    guard let self = self, let container = container else { return }
                    if usage != nil {
                        dataObserver?.dispose()
                        dataObserver = container.reactionUsageObservable
                            .map { $0.quantity }
                            .subscribe(onNext: { [weak self] in
                                self?.fillData(
                                    countText: R.string.localizable.numberOfReactions($0.commaRepresentation),
                                    actionDescriptionText: R.string.localizable.you_gave())
                            })

                        dataObserver?
                            .disposed(by: self.disposeBag)
                    } else {
                        dataObserver?.dispose()
                        self.fillData(
                            countText: R.string.localizable.numberOfReactions("0"),
                            actionDescriptionText: R.string.localizable.you_gave())
                    }
                })
                .disposed(by: disposeBag)

        default:
            break
        }
    }

    func setProperties(section: Section) {
        self.section = section

        switch section {
        case .mood:
            fillData(countText: R.string.localizable.yourMood().localizedUppercase,
                     actionDescriptionText: R.string.localizable.sentimentAnalysisOfYourPosts())

        case .aggregateAnalysis:
            fillData(countText: R.string.phrase.aggAnalysisHeading().localizedUppercase,
                     actionDescriptionText: R.string.phrase.aggAnalysisSubHeading())

        default:
            break
        }
    }

    func fillData(countText: String?, actionDescriptionText: String?) {
        countLabel.text = countText
        actionDescriptionLabel.text = actionDescriptionText
        countLabel.flex.markDirty()
        actionDescriptionLabel.flex.markDirty()
        flex.layout()
    }
}
