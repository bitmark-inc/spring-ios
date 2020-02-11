//
//  LaunchingDeeplinkViewController.swift
//  Spring
//
//  Created by Thuyen Truong on 1/20/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit

class LaunchingDeeplinkViewController: ViewController {

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func setupViews() {
        setupBackground(backgroundView: ImageView(image: R.image.onboardingSplash()))
        super.setupViews()

        contentView.backgroundColor = .clear

        // *** Setup subviews ***
        let titleScreen = Label()
        titleScreen.apply(
            text: R.string.phrase.launchName().localizedUppercase,
            font: R.font.domaineSansTextLight(size: 80),
            colorTheme: .white)

        let descriptionLabel = Label()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.apply(
            text: R.string.phrase.launchDescription(),
            font: R.font.atlasGroteskLight(size: 22),
            colorTheme: .white, lineHeight: 1.125)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .alignItems(.center)
            .direction(.column).define { (flex) in
                flex.addItem(titleScreen).marginTop(123)
                flex.addItem(descriptionLabel)
            }
    }
}
