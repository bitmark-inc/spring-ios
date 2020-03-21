//
//  CoverLayerView.swift
//  Spring
//
//  Created by Thuyen Truong on 3/20/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CoverLayerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white
        alpha = 0.5
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
