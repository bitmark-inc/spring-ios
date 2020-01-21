//
//  Application.swift
//  Spring
//
//  Created by Anh Nguyen on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

final class Application: NSObject {
    static let shared = Application()

    var window: UIWindow?
    let navigator: Navigator

    private override init() {
        navigator = Navigator.default
        super.init()
        updateProvider()
    }

    private func updateProvider() {
    }

    func presentInitialScreen(in window: UIWindow?, fromDeeplink: Bool) {
        updateProvider()
        guard let window = window else { return }
        self.window = window

        self.navigator.show(
            segue: fromDeeplink ? .launchingDeeplinkNavigation : .launchingNavigation,
            sender: nil, transition: .root(in: window))
    }
}
