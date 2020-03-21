//
//  HeaderReuseView.swift
//  Spring
//
//  Created by Thuyen Truong on 3/16/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit

class HeaderReuseView: UICollectionReusableView {

    lazy var sectionHeader = makeSectionFilter()

    var showSeparation: Bool = true {
        didSet {
            sectionHeader.separation.isHidden = !showSeparation
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(sectionHeader)

        sectionHeader.snp.makeConstraints { (make) in
            make.edges.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setData(periodName: [String]) {
        sectionHeader.periodName = periodName
    }

    fileprivate func makeSectionFilter() -> SectionFilter {
        let sectionFilter = SectionFilter()
        sectionFilter.backgroundColor = .white
        return sectionFilter
    }
}
