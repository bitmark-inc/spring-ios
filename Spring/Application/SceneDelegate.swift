//
//  SceneDelegate.swift
//  Spring
//
//  Created by Anh Nguyen on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import SVProgressHUD

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        window?.makeKeyAndVisible()

        SVProgressHUD.setContainerView(window)

        // Show initial screen
        if let url = connectionOptions.urlContexts.first?.url {
            Application.shared.presentInitialScreen(in: window!, fromDeeplink: true)
            Navigator.handleDeeplink(url: url)
        } else {
            Application.shared.presentInitialScreen(in: window!, fromDeeplink: false)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        guard Global.current.account != nil else { return }
        Navigator.evaluatePolicyWhenUserSetEnable()
        Navigator.refreshOnboardingStateIfNeeded()
        Global.pollingSyncAppArchiveStatus()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        UserDefaults.standard.enteredBackgroundTime = Date()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url
            else {
                return
        }

        Navigator.handleDeeplink(url: url)
    }
}
