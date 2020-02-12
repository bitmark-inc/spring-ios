//
//  AggregateAnalysisView.swift
//  Spring
//
//  Created by Thuyen Truong on 2/12/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class AggregateAnalysisView: UIView {

    // MARK: - Properties
    fileprivate lazy var sectionHeadingView = makeSectionHeadingView()
    fileprivate lazy var subHeadingView = makeSubHeadingView()
    fileprivate lazy var postStatsView = makeStatGeneralView(by: .post)
    fileprivate lazy var reactionStatsView = makeStatGeneralView(by: .reaction)

    let disposeBag = DisposeBag()

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column)
            .padding(0, 18, 43, 18)
            .define { (flex) in
                flex.addItem(sectionHeadingView)
                flex.addItem(subHeadingView).marginTop(7)
                flex.addItem(postStatsView).marginTop(35)
                flex.addItem(reactionStatsView).marginTop(14)
            }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Handlers
    func setProperties(container: UsageViewController) {
        weak var container = container

        container?.postStatsObservable
            .map { GraphDataConverter.getStats(with: $0, in: .post) }
            .subscribe(onNext: { [weak self] (statsData) in
                self?.postStatsView.fillData(with: statsData)
            })
            .disposed(by: disposeBag)

        container?.reactionStatsObservable
            .map { GraphDataConverter.getStats(with: $0, in: .reaction) }
            .subscribe(onNext: { [weak self] (statsData) in
                self?.reactionStatsView.fillData(with: statsData)
            })
            .disposed(by: disposeBag)
    }
}

extension AggregateAnalysisView {
    fileprivate func makeSectionHeadingView() -> SectionHeadingView {
        let sectionHeadingView = SectionHeadingView()
        sectionHeadingView.setProperties(section: .aggregateAnalysis)
        return sectionHeadingView
    }

    fileprivate func makeSubHeadingView() -> UIView {
        func makeCircle(_ color: UIColor) -> UIView {
            let view = UIView()
            view.cornerRadius = 6
            view.backgroundColor = color
            view.flex.height(12).width(12).marginRight(5)
            return view
        }

        func makeLabel(text: String) -> Label {
            let label = Label()
            label.apply(text: text,
                        font: R.font.atlasGroteskLight(size: 10),
                        colorTheme: .black, lineHeight: 1.056)
            return label
        }

        let view = UIView()
        view.flex.direction(.row).define { (flex) in
            flex.addItem(makeCircle(ColorTheme.indianKhaki.color))
            flex.addItem(makeLabel(text: R.string.phrase.aggAnalysisSpringUserAvergatePosts()))

            if AppArchiveStatus.currentState == .done {
                flex.addItem(makeCircle(ColorTheme.cognac.color)).marginLeft(18)
                flex.addItem(makeLabel(text: R.string.localizable.your_posts()))
            }
        }
        return view
    }

    fileprivate func makeStatGeneralView(by section: Section) -> StatsChartView {
        return StatsChartView(headingTitle: section == .post
            ? R.string.localizable.postsByType()
            : R.string.localizable.reactionsByType())
    }
}
