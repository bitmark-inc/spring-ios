//
//  SectionSeparator.swift
//  Spring
//
//  Created by Thuyen Truong on 12/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout

class SectionSeparator: UIView {

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        flex.direction(.column).define { (flex) in
            flex.addItem()
                .backgroundColor(UIColor(hexString: "#828180")!)
                .marginTop(3)
                .marginLeft(0)
                .marginRight(0)
                .height(1)
            flex.addItem()
                .backgroundColor(UIColor(hexString: "#828180")!)
                .marginTop(3)
                .marginLeft(0)
                .marginRight(0)
                .height(1)
        }
    }

    convenience init(autoLayout: Bool) {
        self.init()

        func makeLine() -> UIView {
            let line = UIView()
            line.backgroundColor = UIColor(hexString: "#828180")!
            return line
        }

        let line1 = makeLine()
        let line2 = makeLine()

        addSubview(line1)
        addSubview(line2)

        line1.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(3)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        line2.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class SingleSeparator: UIView {
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column).define { (flex) in
            flex.addItem()
                .backgroundColor(UIColor(hexString: "#828180")!)
                .marginLeft(0)
                .marginRight(0)
                .height(1)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
