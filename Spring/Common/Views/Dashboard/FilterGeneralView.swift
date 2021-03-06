//
//  FilterGeneralView.swift
//  Spring
//
//  Created by Thuyen Truong on 12/23/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import Charts

class FilterGeneralView: UIView {

    // MARK: - Properties
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 14))
    let chartView = HorizontalBarChartView()
    let fixedBarHeight: CGFloat = 4

    var section: Section = .post
    var groupKey: GroupKey = .friend
    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    weak var navigatorDelegate: NavigatorDelegate?
    let disposeBag = DisposeBag()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        flex.direction(.column).marginTop(2).define { (flex) in
            flex.addItem(headingLabel).marginLeft(18).marginRight(18)
            flex.addItem(chartView).margin(3, 20, 0, 5)
        }

        chartView.drawBarShadowEnabled = false
        chartView.drawValueAboveBarEnabled = true
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.dragEnabled = false
        chartView.highlightPerTapEnabled = true
        chartView.delegate = self

        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        xAxis.labelFont = R.font.atlasGroteskLight(size: 12)!

        let leftAxis = chartView.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.drawAxisLineEnabled = false
        leftAxis.drawLabelsEnabled = false
        leftAxis.drawGridLinesEnabled = false

        let rightAxis = chartView.rightAxis
        rightAxis.axisMinimum = 0
        rightAxis.drawAxisLineEnabled = false
        rightAxis.drawLabelsEnabled = false
        rightAxis.drawGridLinesEnabled = false

        let l = chartView.legend
        l.enabled = false
        chartView.fitBars = true

        let xAxisRender = chartView.xAxisRenderer
        chartView.xAxisRenderer = CustomxAxisRender(
            viewPortHandler: xAxisRender.viewPortHandler,
            xAxis: xAxis,
            transformer: xAxisRender.transformer,
            chart: chartView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(section: Section, groupKey: GroupKey, container: UsageViewController) {
        weak var container = container
        self.section = section
        self.groupKey = groupKey

        var dataObserver: Disposable? // stop observing old-data

        switch groupKey {
        case .friend:
            headingLabel.setText(R.string.localizable.byFriendTagged())
        case .place:
            headingLabel.setText(R.string.localizable.byPlaceTagged())
        default:
            break
        }

        switch section {
        case .post:
            container?.thisViewModel.realmPostUsageRelay
                .subscribe(onNext: { [weak self] (usage) in
                    guard let self = self, let container = container else { return }
                    if usage != nil {
                        dataObserver?.dispose()
                        dataObserver = container.groupsPostUsageObservable
                            .map { groupKey == .friend ? $0.friend : $0.place }
                            .map { (graphDatas) -> [(names: [String], sumData: Double, data: [Double])]? in
                                guard let graphDatas = graphDatas
                                    else {
                                        return nil
                                }

                                return GraphDataConverter.getDataGroupByNameValue(
                                    with: graphDatas,
                                    in: .post)
                            }
                            .subscribe(onNext: { [weak self] (data) in
                                self?.fillData(with: data)
                            })

                        dataObserver?
                            .disposed(by: self.disposeBag)
                    } else {
                        dataObserver?.dispose()
                        self.fillData(with: nil)
                    }
                })
                .disposed(by: disposeBag)

        case .reaction:
            container?.thisViewModel.realmReactionUsageRelay
                .subscribe(onNext: { [weak self] (usage) in
                    guard let self = self, let container = container else { return }
                    if usage != nil {
                        dataObserver?.dispose()
                        dataObserver = container.groupsReactionUsageObservable
                            .map { groupKey == .friend ? $0.friend : $0.place }
                            .map { (graphDatas) -> [(names: [String], sumData: Double, data: [Double])]? in
                                guard let graphDatas = graphDatas
                                    else {
                                        return nil
                                }

                                return GraphDataConverter.getDataGroupByNameValue(
                                    with: graphDatas,
                                    in: .post)
                            }
                            .subscribe(onNext: { [weak self] (data) in
                                self?.fillData(with: data)
                            })

                        dataObserver?
                            .disposed(by: self.disposeBag)
                    } else {
                        dataObserver?.dispose()
                        self.fillData(with: nil)
                    }
                })
                .disposed(by: disposeBag)

        default:
            break
        }
    }

    fileprivate func fillData(with data: [(names: [String], sumData: Double, data: [Double])]?) {
        if let data = data, data.count > 0 {
            var friends = [String]()
            var entries = [BarChartDataEntry]()
            for (index, (names, _, data)) in data.reversed().enumerated() {
                friends.append(names.count == 1 ? names.first! : R.string.localizable.graphKeyOther())
                entries.append(BarChartDataEntry(x: Double(index), yValues: data, data: names))
            }

            let barChartDataSet = BarChartDataSet(entries: entries)
            switch section {
            case .post:
                barChartDataSet.colors = PostType.barChartColors
            case .reaction:
                barChartDataSet.colors = ReactionType.barChartColors
            default:
                break
            }

            let barData = BarChartData(dataSet: barChartDataSet)
            barData.setValueFont(R.font.atlasGroteskLight(size: 12)!)
            barData.barWidth = 0.15
            barData.setValueFormatter(StackedBarValueFormatter(isHorizontal: true))

            chartView.data = barData
            chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: friends)
            chartView.xAxis.labelCount = data.count
            chartView.legend.enabled = false

            let chartViewHeight: CGFloat!

            if data.count == 1 {
                chartViewHeight = (fixedBarHeight / 0.15 + 30)
            } else {
                chartViewHeight = (fixedBarHeight / 0.15 + 14) * CGFloat(data.count)
            }
            chartView.flex.height(chartViewHeight)
            flex.height(chartViewHeight + 30)
        } else {
            chartView.clear()
            chartView.flex.height(0)
            flex.height(0)
        }

        flex.markDirty()
        containerLayoutDelegate?.layout()
    }
}

extension FilterGeneralView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        chartView.highlightValues(nil)

        guard let selectedValue = entry.data else { return }

        switch section {
        case .post:
            navigatorDelegate?.goToPostListScreen(filterBy: groupKey, filterValue: selectedValue)
        default:
            return
        }
    }
}
