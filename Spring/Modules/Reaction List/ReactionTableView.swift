//
//  ReactionTableView.swift
//  Spring
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift
import Realm

class ReactionTableView: TableView {
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.register(cellWithClass: ListHeadingViewCell.self)
        self.register(cellWithClass: ReactionTableViewCell.self)
        self.register(cellWithClass: FooterCell.self)

        themeService.rx
            .bind({ $0.background }, to: rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ReactionTableView {
    static func makeFooterView() -> UIView {
        let separatorLine = SectionSeparator(autoLayout: true)
        let view = UIView()
        view.addSubview(separatorLine)
        separatorLine.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return view
    }
}
