//
//  ListSectionDelegate.swift
//  Spring
//
//  Created by Thuyen Truong on 3/16/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit

protocol ListSectionDelegate {
    func makeSectionElements(timeUnit: SecondaryTimeUnit, timestamp: Date) -> [String]
    func makeFilterSegment() -> FilterSegment
    func makeSectionView(periodName: [String]) -> SectionFilter
    func makeHeaderView(sectionHeader: SectionFilter) -> UIView
    func makeFooterView() -> UIView
}

extension ListSectionDelegate {
    func makeSectionElements(timeUnit: SecondaryTimeUnit, timestamp: Date) -> [String] {
        switch timeUnit {
        case .month:
            return [timestamp.monthName(), "\(timestamp.year)"]
        case .year:
            return ["\(timestamp.year)"]
        case .decade:
            return [timestamp.year.decadeText]
        }
    }

    func makeFilterSegment() -> FilterSegment {
        return FilterSegment(elements: [
            R.string.localizable.month().localizedUppercase,
            R.string.localizable.year().localizedUppercase,
            R.string.localizable.decade().localizedUppercase
        ])
    }

    func makeSectionView(periodName: [String]) -> SectionFilter {
        let sectionFilter = SectionFilter()
        sectionFilter.periodName = periodName
        sectionFilter.backgroundColor = .white
        return sectionFilter
    }

    func makeHeaderView(sectionHeader: SectionFilter) -> UIView {
        let view = UIView()
        view.addSubview(sectionHeader)

        sectionHeader.snp.makeConstraints { (make) in
            make.edges.centerY.equalToSuperview()
        }

        return view
    }

    func makeFooterView() -> UIView {
        let separatorLine = SectionSeparator(autoLayout: true)
        let view = UIView()
        view.addSubview(separatorLine)
        separatorLine.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return view
    }
}
