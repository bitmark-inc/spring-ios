//
//  PostTableView.swift
//  Spring
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift
import Realm

class PostTableView: TableView {
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.register(cellWithClass: ListHeadingViewCell.self)
        self.register(cellWithClass: MediaPostTableViewCell.self)
        self.register(cellWithClass: UpdatePostTableViewCell.self)
        self.register(cellWithClass: LinkPostTableViewCell.self)

        themeService.rx
            .bind({ $0.background }, to: rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PostTableView {
    static func extractPostCell(with post: Post, _ tableView: UITableView, _ indexPath: IndexPath) -> PostDataTableViewCell {
        switch PostType(rawValue: post.type) {
        case .update:
            return tableView.dequeueReusableCell(withClass: UpdatePostTableViewCell.self, for: indexPath)
        case .link:
            return tableView.dequeueReusableCell(withClass: LinkPostTableViewCell.self, for: indexPath)
        case .media:
            if post.mediaData.count > 0 {
                return tableView.dequeueReusableCell(withClass: MediaPostTableViewCell.self, for: indexPath)
            } else {
                fallthrough
            }
        default:
            return tableView.dequeueReusableCell(withClass: UpdatePostTableViewCell.self, for: indexPath)
        }
    }

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
