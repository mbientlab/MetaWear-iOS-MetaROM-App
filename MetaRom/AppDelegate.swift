//
//  AppDelegate.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 4/25/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        IQKeyboardManager.shared.enable = true
        Globals.cloudSyncMode = false
        
        // Point the user to their correct local database
        let folderName = "METAROM\(Globals.cloudSyncMode ? "-cloud" : "-local")"
        let realmFolder = Globals.documentDirectory.appendingPathComponent(folderName, isDirectory: true)
        // Create folder if needed, and allow background access to the realm
        try? FileManager.default.createDirectory(at: realmFolder,
                                                 withIntermediateDirectories: false,
                                                 attributes: [.protectionKey : FileProtectionType.completeUntilFirstUserAuthentication])
        let realmURL = realmFolder.appendingPathComponent("default.realm")
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            fileURL: realmURL,
            schemaVersion: 2,
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 2) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
            })
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        Globals.backgroundDate = Date()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        //logOutIfExpired(application)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

//func logOutIfExpired(_ application: UIApplication) {
//    if Globals.backgroundDate.timeIntervalSinceNow < -Globals.autoLogoutTime {
//        PFUser.logOutInBackground()
//        Globals.expirationDate = Date(timeIntervalSince1970: 0)
//        let navigationController = application.windows[0].rootViewController as! UINavigationController
//        navigationController.popToRootViewController(animated: false)
//    }
//}
