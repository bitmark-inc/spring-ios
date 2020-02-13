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
    let disposeBag = DisposeBag()

    convenience init(headingTitle: String) {
        self.init()
        headingLabel.setText(headingTitle.localizedUppercase)
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        flex.direction(.column).define { (flex) in
            flex.addItem(headingLabel)
            flex.addItem(chartView).margin(10, 10, 0, 70)
        }

        chartView.drawBarShadowEnabled = false
        chartView.drawValueAboveBarEnabled = true
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.dragEnabled = false
        chartView.highlightPerTapEnabled = true

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
        chartView.extraBottomOffset = 2

        let xAxisRender = chartView.xAxisRenderer
        let customXAxisRender = CustomxAxisRender(
            viewPortHandler: xAxisRender.viewPortHandler,
            xAxis: xAxis,
            transformer: xAxisRender.transformer,
            chart: chartView)
        customXAxisRender.yShift = CGFloat(35.0)
        chartView.xAxisRenderer = customXAxisRender
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func fillData(with data: [(name: String, data: StatsData)]) {
        let groupSpace = 0.7
        let barSpace = 0.05
        let barWidth = 0.1

        var avgDataEntries = [BarChartDataEntry]()
        var totalDataEntries = [BarChartDataEntry]()

        for (index, (_, d)) in data.reversed().enumerated() {
            avgDataEntries.append(BarChartDataEntry(x: Double(index), y: d.sysAvg))
            totalDataEntries.append(BarChartDataEntry(x: Double(index), y: d.count))
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
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: data.reversed().map { "graph.key.\($0.name)".localized() })
        chartView.legend.enabled = false
        chartView.xAxis.granularity = 1
        chartView.xAxis.axisMinimum = 0
        chartView.xAxis.axisMaximum = barData.groupWidth(groupSpace: groupSpace, barSpace: barSpace) * Double(data.count)

        let chartViewHeight = (fixedBarHeight / 0.15 + 14) * CGFloat(data.count)
        chartView.flex.height(chartViewHeight)
        flex.height(chartViewHeight + 30)
        flex.markDirty()
    }
}
