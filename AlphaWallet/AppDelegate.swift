// Copyright © 2022 Stormbird PTE. LTD.

import UIKit
import AlphaWalletNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private var appCoordinator: AppCoordinator!
    private var application: Application!
    var window: UIWindow?
    //NOTE: create backgroundTaskService as soon as possible, code might not be executed when task get created too late
    private let backgroundTaskService: BackgroundTaskService = BackgroundTaskServiceImplementation()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.application = Application.shared
        
        UNUserNotificationCenter.current().delegate = self

        //Keep this log because it's really useful for debugging things without requiring a new TestFlight/app store submission
        NSLog("Application launched with launchOptions: \(String(describing: launchOptions))")
        appCoordinator = AppCoordinator.create(application: self.application)
        self.window = appCoordinator.window
        appCoordinator.start(launchOptions: launchOptions)

        #if DEBUG
        let longpress: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(debugTap(_:)))
        longpress.numberOfTouchesRequired = 1
        self.window?.addGestureRecognizer(longpress)
        #endif
        return true
    }
    
    @objc func debugTap(_ ges: UILongPressGestureRecognizer) {
        switch ges.state {
        case .began:
            if let tab = self.window?.rootViewController as? UITabBarController, let nav = tab.selectedViewController as? UINavigationController, let vc = nav.topViewController {
                UIWindow.toast("\(vc)")
            } else if let nav = self.window?.rootViewController as? UINavigationController, let vc = nav.topViewController {
                if let tab = vc as? UITabBarController, let nav = tab.selectedViewController as? UINavigationController, let vc = nav.topViewController {
                    UIWindow.toast("\(vc)")
                } else {
                    UIWindow.toast("\(vc)")
                }
            }
        default:
            break
        }
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem) async -> Bool {
        await self.application.applicationPerformActionFor(shortcutItem)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        appCoordinator.applicationWillResignActive()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        appCoordinator.applicationDidBecomeActive()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        appCoordinator.applicationDidEnterBackground()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        appCoordinator.applicationWillEnterForeground()
    }

    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        return self.application.applicationShouldAllowExtensionPointIdentifier(extensionPointIdentifier)
    }

    // URI scheme links and AirDrop
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        //Keep this log because it's really useful for debugging things without requiring a new TestFlight/app store submission
        NSLog("Application open url: \(url.absoluteString) options: \(options)")
        return self.application.applicationOpenUrl(url, options: options)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        NSLog("Application open userActivity: \(userActivity)")
        return self.application.applicationContinueUserActivity(userActivity, restorationHandler: restorationHandler)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.application.pushNotificationsService.register(deviceToken: .success(deviceToken))
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        self.application.pushNotificationsService.register(deviceToken: .failure(error))
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        NSLog("Application receive remote notification: \(userInfo)")

        let task: BackgroundTaskIdentifier?
        switch UIApplication.shared.applicationState {
        case .background:
            task = backgroundTaskService.startTask()
        default:
            task = nil
        }
        let result = await self.application.pushNotificationsService.handle(remoteNotification: userInfo)
        if let task = task {
            backgroundTaskService.endTask(with: task)
        }

        return result
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        await application.pushNotificationsService.userNotificationCenter(center, willPresent: notification)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await application.pushNotificationsService.userNotificationCenter(center, didReceive: response)
    }
}

extension UIApplicationShortcutItem: @unchecked Sendable {}
