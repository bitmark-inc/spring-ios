//
//  SectionFilter.swift
//  Spring
//
//  Created by Thuyen Truong on 3/11/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class SectionFilter: UIView {

    // MARK: - Properties
    fileprivate lazy var periodNameLabel = makePeriodNameLabel()
    fileprivate lazy var subPeriodNameLabel = makeSubPeriodNameLabel()
    lazy var separation = SectionSeparator()

    var periodName: [String] = [] {
        didSet {
            switch periodName.count {
            case 0: return
            case 1:
                periodNameLabel.setText(periodName[0].localizedUppercase)
                subPeriodNameLabel.setText(nil)

            default:
                periodNameLabel.setText(periodName[0].localizedUppercase)
                subPeriodNameLabel.setText(periodName[1].localizedUppercase)
            }

        }
    }

    let disposeBag = DisposeBag()
 
    override init(frame: CGRect) {
        super.init(frame: frame)

        let nameLabels = UIView()
        nameLabels.addSubview(periodNameLabel)
        nameLabels.addSubview(subPeriodNameLabel)

        periodNameLabel.snp.makeConstraints { (make) in
            make.top.leading.bottom.equalToSuperview()
        }

        subPeriodNameLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(periodNameLabel.snp.trailing).offset(5)
            make.top.bottom.trailing.equalToSuperview()
        }

        addSubview(nameLabels)
        addSubview(separation)

        nameLabels.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
        }

        separation.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension SectionFilter {
    fileprivate func makePeriodNameLabel() -> Label {
        let label = Label()
        label.apply(font: R.font.domaineSansTextLight(size: 19), colorTheme: .black)
        label.textAlignment = .center
        return label
    }

    fileprivate func makeSubPeriodNameLabel() -> Label {
        let label = Label()
        label.apply(font: R.font.domaineSansTextLight(size: 18), colorTheme: .tundora)
        label.textAlignment = .center
        return label
    }
}
