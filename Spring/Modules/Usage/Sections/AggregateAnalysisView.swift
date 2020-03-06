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
    weak var containerLayoutDelegate: ContainerLayoutDelegate?

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column)
            .padding(0, 18, 38, 18)
            .define { (flex) in
                flex.addItem(sectionHeadingView)
                flex.addItem(subHeadingView).marginTop(7)
                flex.addItem(postStatsView).marginTop(35)
                flex.addItem(reactionStatsView).marginTop(14)
            }

        AppArchiveStatus.currentState
            .filter { $0?.rawValue == "processed" }
            .subscribe(onNext: { [weak self, weak subHeadingView] (_) in
                guard let self = self, let subHeadingView = subHeadingView else { return }
                subHeadingView.flex.addItem(self.makeCircle(ColorTheme.cognac.color)).marginLeft(18)
                subHeadingView.flex.addItem(self.makeSubHeadingLabel(text: R.string.localizable.your_posts_and_reactions()))
            })
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Handlers
    func setProperties(container: UsageViewController) {
        weak var container = container
        var postStatsdataObserver: Disposable? // stop observing old-data
        var reactionStatsdataObserver: Disposable?

        container?.thisViewModel.realmPostStatsRelay
            .subscribe(onNext: { [weak self] (stats) in
                guard let self = self else { return }

                if let stats = stats {
                    postStatsdataObserver?.dispose()

                    postStatsdataObserver = Observable.from(object: stats)
                        .map { try Converter<StatsGroups>(from: $0.groups).value }
                        .map { GraphDataConverter.getStats(with: $0, in: .post) }
                        .subscribe(onNext: { [weak self] (statsData) in
                            self?.postStatsView.fillData(with: statsData)
                            self?.layout(in: .post)
                        })

                    postStatsdataObserver?.disposed(by: self.disposeBag)
                } else {
                    self.postStatsView.fillData(with: nil)
                    self.layout(in: .post)
                }
            })
            .disposed(by: disposeBag)

        container?.thisViewModel.realmReactionStatsRelay
            .subscribe(onNext: { [weak self] (stats) in
                guard let self = self else { return }

                if let stats = stats {
                    reactionStatsdataObserver?.dispose()

                    reactionStatsdataObserver = Observable.from(object: stats)
                        .map { try Converter<StatsGroups>(from: $0.groups).value }
                        .map { GraphDataConverter.getStats(with: $0, in: .reaction) }
                        .subscribe(onNext: { [weak self] (statsData) in
                            self?.reactionStatsView.fillData(with: statsData)
                            self?.layout(in: .reaction)
                        })

                    reactionStatsdataObserver?.disposed(by: self.disposeBag)
                } else {
                    self.reactionStatsView.fillData(with: nil)
                    self.layout(in: .reaction)
                }

            })
            .disposed(by: disposeBag)
    }

    fileprivate func layout(in section: Section) {
        switch section {
        case .post:
            postStatsView.chartView.flex.markDirty()
            postStatsView.flex.layout()
        case .reaction:
            reactionStatsView.chartView.flex.markDirty()
            reactionStatsView.flex.layout()
        default:
            break
        }
        containerLayoutDelegate?.layout()
    }
}

extension AggregateAnalysisView {
    fileprivate func makeSectionHeadingView() -> SectionHeadingView {
        let sectionHeadingView = SectionHeadingView()
        sectionHeadingView.setProperties(section: .aggregateAnalysis)
        return sectionHeadingView
    }

    fileprivate func makeSubHeadingView() -> UIView {
        let view = UIView()
        view.flex.direction(.row).define { (flex) in
            flex.addItem(makeCircle(ColorTheme.indianKhaki.color))
            flex.addItem(makeSubHeadingLabel(text: R.string.phrase.aggAnalysisSpringUserAvergatePosts()))
        }
        return view
    }

    fileprivate func makeStatGeneralView(by section: Section) -> StatsChartView {
        return StatsChartView(headingTitle: section == .post
            ? R.string.localizable.postsByType()
            : R.string.localizable.reactionsByType())
    }

    func makeCircle(_ color: UIColor) -> UIView {
        let view = UIView()
        view.cornerRadius = 6
        view.backgroundColor = color
        view.flex.height(12).width(12).marginRight(5)
        return view
    }

    func makeSubHeadingLabel(text: String) -> Label {
        let label = Label()
        label.apply(text: text,
                    font: R.font.atlasGroteskLight(size: 10),
                    colorTheme: .black, lineHeight: 1.056)
        return label
    }
}
