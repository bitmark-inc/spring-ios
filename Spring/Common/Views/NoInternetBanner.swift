//
//  NoInternetBanner.swift
//  Spring
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import SwiftEntryKit

class NoInternetBanner {
    static var noInternetConnectionAttributes: EKAttributes = {
        var attributes = EKAttributes.topToast
        attributes.entryBackground = .color(color: EKColor(UIColor(hexString: "#828180")))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.3), scale: .init(from: 1, to: 0.7, duration: 0.7)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 10, offset: .zero))
        attributes.displayDuration = 1.5
        attributes.statusBar = .hidden
        return attributes
    }()

    static let banner: EKNoteMessageView = {
        let title = EKProperty.LabelContent(
            text: R.string.error.noInternetConnection(),
            style: EKProperty.LabelStyle(font: R.font.atlasGroteskLight(size: 12)!, color: EKColor(.white), alignment: .center))

        return EKNoteMessageView(with: title)
    }()

    static func show() {
        DispatchQueue.main.async {
            SwiftEntryKit.display(entry: banner, using: noInternetConnectionAttributes)
        }
    }

    static func hide() {
        DispatchQueue.main.async {
            SwiftEntryKit.dismiss()
        }
    }
}
