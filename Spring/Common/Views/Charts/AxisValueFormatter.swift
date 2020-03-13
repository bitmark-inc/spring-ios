//
//  AxisValueFormatter.swift
//  Spring
//
//  Created by Thuyen Truong on 3/12/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Charts

extension Double {
    var abbreviated: String {
        let abbrev = "KMBTPE"
        return abbrev.enumerated().reversed().reduce(nil as String?) { accum, tuple in
            let factor = self / pow(10, Double(tuple.0 + 1) * 3)
            let format = (factor.truncatingRemainder(dividingBy: 1)  == 0 ? "%.0f%@" : "%.1f%@")

            return accum ?? (factor > 1 ? String(format: format, factor, String(tuple.1)) : nil)
        } ?? self.clean()
    }

    func clean() -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: self as NSNumber) ?? ""
    }
}


class AxisValueFormatter: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return value.abbreviated
    }
}
