//
//  AppDelegate.swift
//  Spring
//
//  Created by Anh Nguyen on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import Intercom
import OneSignal
import SVProgressHUD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()

        // init BitmarkSDK environment & api_token
        BitmarkSDKService.setupConfig()

        // SVProgressHUD
        SVProgressHUD.setContainerView(window)
        SVProgressHUD.setMinimumDismissTimeInterval(0.5)
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setHapticsEnabled(true)

        // setup Intercom
        Intercom.setApiKey(Constant.default.intercomAppKey, forAppId: Constant.default.intercomAppID)
        
        // Local Notification
        UNUserNotificationCenter.current().delegate = self

        // OneSignal
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]

        OneSignal.initWithLaunchOptions(
            launchOptions,
            appId: Constant.default.oneSignalAppID,
            handleNotificationAction: nil,
            settings: onesignalInitSettings
        )

        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification
        OneSignal.setLocationShared(false)

        // IQKeyboardManager
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.enableAutoToolbar = false

        if #available(iOS 13, *) {
            // already execute app flow in SceneDelegate
        } else {
            Application.shared.presentInitialScreen(
                in: window!,
                fromDeeplink: (launchOptions ?? [:]).count > 0)
        }

        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        UserDefaults.standard.enteredBackgroundTime = Date()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        Navigator.evaluatePolicyWhenUserSetEnable()
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let scheme = url.scheme, scheme == Constant.appURLScheme
            else {
                return false
        }

        Navigator.handleDeeplink(url: url)
        return true
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        Global.log.info("handleEventsForBackgroundURLSession: \(identifier)")
        let backgroundSession = BackgroundTaskManager.shared.urlSession(identifier: identifier)
        Global.log.debug("Rejoining session \(backgroundSession)")

        BackgroundTaskManager.shared.addCompletionHandler(handler: completionHandler, identifier: identifier)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        Global.pollingSyncAppArchiveStatus()
    }
}
