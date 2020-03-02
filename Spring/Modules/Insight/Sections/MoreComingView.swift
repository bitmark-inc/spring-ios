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
    fileprivate lazy var titleLabel = makeTitleLabel()
    fileprivate lazy var descriptionLabel = makeDescriptionLabel()
    fileprivate lazy var notifyMeButton = makeNotifyMeButton()

    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    let disposeBag = DisposeBag()
    var section: Section = .moreInsightsComing {
        didSet {
            switch section {
            case .moreInsightsComing:
                titleLabel.setText(R.string.phrase.moreInsightsComingTitle().localizedUppercase)
            case .morePersonalAnalyticsComing:
                titleLabel.setText(R.string.phrase.morePersonalAnalyticsComingTitle().localizedUppercase)
            default:
                return
            }
        }
    }

    var notifyMeButtonHeight: CGFloat = 30

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column)
            .padding(30, 18, 18, 18)
            .define { (flex) in
                flex.addItem(titleLabel)
                flex.addItem(descriptionLabel).marginTop(7)
                flex.addItem(notifyMeButton).marginTop(20).height(notifyMeButtonHeight)
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
                    self.notifyMeButton.flex.height(self.notifyMeButtonHeight).marginTop(20)
                    self.descriptionLabel.setText(self.makeDescription(withNotify: true))

                default:
                    self.notifyMeButton.isHidden = true
                    self.notifyMeButton.flex.height(0).marginTop(0)
                    self.descriptionLabel.setText(self.makeDescription(withNotify: false))
                }

                self.notifyMeButton.flex.markDirty()
                self.descriptionLabel.flex.markDirty()
                self.containerLayoutDelegate?.layout()
            }
        }
    }
}

extension MoreComingView {
    fileprivate func makeTitleLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            font: R.font.domaineSansTextLight(size: 22),
            colorTheme: .black, lineHeight: 1.056)
        return label
    }

    fileprivate func makeDescriptionLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            font: R.font.atlasGroteskLight(size: 16),
            colorTheme: .black, lineHeight: 1.25)
        return label
    }

    fileprivate func makeNotifyMeButton() -> Button {
        let button = Button()
        button.contentHorizontalAlignment = .leading
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        button.apply(
            title: R.string.localizable.notify_me(),
            font: R.font.atlasGroteskRegular(size: 16),
            colorTheme: .cognac)
        return button
    }

    fileprivate func makeDescription(withNotify: Bool) -> String {
        switch section {
        case .moreInsightsComing:
            return withNotify
                ? R.string.phrase.moreInsightsComingDescriptionWithNotify()
                : R.string.phrase.moreInsightsComingDescription()
        case .morePersonalAnalyticsComing:
            return withNotify
                ? R.string.phrase.morePersonalAnalyticsComingDescriptionWithNotify()
                : R.string.phrase.morePersonalAnalyticsComingDescription()
        default:
            return ""
        }
    }
}
