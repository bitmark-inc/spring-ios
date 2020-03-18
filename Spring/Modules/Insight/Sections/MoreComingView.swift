//
//  MoreComingView.swift
//  Spring
//
//  Created by Thuyen Truong on 2/10/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class MoreComingView: UIView {

    // MARK: - Properties
    fileprivate lazy var notifyMeButton = makeNotifyMeButton()

    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    let disposeBag = DisposeBag()

    var notifyMeButtonHeight: CGFloat = 30

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column)
            .padding(30, 18, 18, 18)
            .define { (flex) in
                flex.addItem(notifyMeButton).height(notifyMeButtonHeight)
            }

        reloadState()

        notifyMeButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            NotificationPermission.askForNotificationPermission(handleWhenDenied: true)
                .subscribe()
                .disposed(by: self.disposeBag)
        }.disposed(by: disposeBag)

        NotificationCenter.default.addObserver(self, selector: #selector(reloadState), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc func reloadState() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { [weak self] (settings) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .denied, .notDetermined:
                    self.notifyMeButton.isHidden = false
                    self.notifyMeButton.flex.height(self.notifyMeButtonHeight)

                default:
                    self.notifyMeButton.isHidden = true
                    self.notifyMeButton.flex.height(0)
                }

                self.notifyMeButton.flex.markDirty()
                self.containerLayoutDelegate?.layout()
            }
        }
    }
}

extension MoreComingView {
    fileprivate func makeNotifyMeButton() -> Button {
        let button = Button()
        button.contentHorizontalAlignment = .leading
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        button.apply(
            title: R.string.localizable.notify_me_when_done(),
            font: R.font.atlasGroteskLight(size: 16),
            colorTheme: .internationalKleinBlue)
        return button
    }
}
