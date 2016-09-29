//
//  AppDelegate.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/8/16.
//  Copyright © 2016 Digital Certificates Project.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let resetKey = "nukeItFromOrbit"
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // Override point for customization after application launch.
        resetStateIfNeeded()
        registerJSONLDProcessor()
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        resetStateIfNeeded()
        registerJSONLDProcessor()
        // See if the URL points to a cert file.
        print(url)
        
        // Switch the UI to show the Certificates Display
        let tabBarController = self.window?.rootViewController as? UITabBarController
        tabBarController?.selectedIndex = 1
        
        // Tell the CertificatesViewController to import from this URL.
        NotificationCenter.default.post(name: NotificationNames.importCertificate, object: url)
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        resetStateIfNeeded()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    private func resetStateIfNeeded() {
        let shouldReset = UserDefaults.standard.bool(forKey: resetKey)
        guard shouldReset else {
            // If that flag isn't on, then we don't need to reset.
            return
        }
        defer {
            NotificationCenter.default.post(Notification(name: NotificationNames.allDataReset))
            UserDefaults.standard.set(false, forKey: resetKey)
        }

        // Delete everything in the Documents directory
        for path in Paths.all {
            do {
                let allFiles = try FileManager.default.contentsOfDirectory(atPath: path)
                allFiles.forEach { (fileName) in
                    let filePath = "\(path)/\(fileName)"
                 
                    do {
                        try FileManager.default.removeItem(atPath: filePath)
                    } catch {
                        print("Failed to delete \(fileName) at \(filePath)")
                    }
                }
            } catch {
                print("Unable to reset state completely.")
            }
        }

        Keychain.destroyShared()
    }

    private func registerJSONLDProcessor() {
        self.window?.rootViewController?.view.addSubview(JSONLDProcessor.shared.webView)
    }
}

