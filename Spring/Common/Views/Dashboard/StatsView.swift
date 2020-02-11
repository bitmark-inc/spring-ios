//
//  StatsView.swift
//  Spring
//
//  Created by Anh Nguyen on 2/11/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import Charts

class StatsChartView: UIView {

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
        rightAxis.drawLabelsEnabled = true
        rightAxis.drawGridLinesEnabled = true
        rightAxis.labelFont = R.font.atlasGroteskLight(size: 12)!
        rightAxis.labelTextColor = UIColor(hexString: "#C1C1C1")
        rightAxis.gridLineWidth = 0.5
        rightAxis.gridColor = UIColor(hexString: "#C1C1C1")

        let l = chartView.legend
        l.enabled = false
        chartView.fitBars = true

        let xAxisRender = chartView.xAxisRenderer
        let customXAxisRender = CustomxAxisRender(
            viewPortHandler: xAxisRender.viewPortHandler,
            xAxis: xAxis,
            transformer: xAxisRender.transformer,
            chart: chartView)
        customXAxisRender.yShift = CGFloat(35.0)
        chartView.xAxisRenderer = customXAxisRender
        
//        let rightYAxisRender = chartView.rightYAxisRenderer
//        let customRightYAxisRender = CustomYAxisRenderer(
//            viewPortHandler: rightYAxisRender.viewPortHandler,
//            yAxis: rightAxis,
//            transformer: rightYAxisRender.transformer)
//        customRightYAxisRender.skipFirstGridLine = false
//        chartView.rightYAxisRenderer = customRightYAxisRender
//
//        let leftYAxisRender = chartView.leftYAxisRenderer
//        let customLeftYAxisRender = CustomYAxisRenderer(
//            viewPortHandler: leftYAxisRender.viewPortHandler,
//            yAxis: leftAxis,
//            transformer: leftYAxisRender.transformer)
//        customLeftYAxisRender.skipFirstGridLine = false
//        chartView.leftYAxisRenderer = customLeftYAxisRender
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func fillData(with data: [(name: String, data: (avg: Double, total: Double))]?) {
        let groupSpace = 0.7
        let barSpace = 0.05
        let barWidth = 0.1

        if let data = data, data.count > 0 {
            var avgDataEntries = [BarChartDataEntry]()
            var totalDataEntries = [BarChartDataEntry]()
            
            for (index, (_, d)) in data.reversed().enumerated() {
                avgDataEntries.append(BarChartDataEntry(x: Double(index), y: d.avg))
                totalDataEntries.append(BarChartDataEntry(x: Double(index), y: d.total))
            }
            
            let avgDataSet = BarChartDataSet(entries: avgDataEntries)
            avgDataSet.setColors(UIColor(hexString: "#BBAB8C"))
            let totalDataSet = BarChartDataSet(entries: totalDataEntries)
            totalDataSet.setColors(UIColor(hexString: "#932C19"))

            let barData = BarChartData(dataSets: [totalDataSet, avgDataSet])
            barData.setValueFont(R.font.atlasGroteskLight(size: 12)!)
            barData.barWidth = barWidth
            barData.setDrawValues(false)

            barData.groupBars(fromX: 0, groupSpace: groupSpace, barSpace: barSpace)

            chartView.data = barData
            chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: data.reversed().map { $0.name })
            chartView.legend.enabled = false
            chartView.xAxis.granularity = 1
            chartView.xAxis.axisMinimum = 0
            chartView.xAxis.axisMaximum = barData.groupWidth(groupSpace: groupSpace, barSpace: barSpace) * Double(data.count)

            var chartViewHeight: CGFloat!

            if data.count == 1 {
                chartViewHeight = (fixedBarHeight / 0.15 + 30)
            } else {
                chartViewHeight = (fixedBarHeight / 0.15 + 14) * CGFloat(data.count)
            }
            chartViewHeight += 30
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

extension StatsChartView: ChartViewDelegate {
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
