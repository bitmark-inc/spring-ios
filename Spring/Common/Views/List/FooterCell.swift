//
//  FooterCell.swift
//  Spring
//
//  Created by Thuyen Truong on 3/21/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import SwiftDate

class FooterCell: TableViewCell {

    // MARK: - Inits
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem(SectionSeparator())
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

