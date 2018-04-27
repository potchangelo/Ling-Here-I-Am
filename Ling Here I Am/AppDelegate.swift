//
//  AppDelegate.swift
//  Ling Here I Am
//
//  Created by Potchara Puttawanchai on 26/4/2561 BE.
//  Copyright © 2561 Potchara Puttawanchai. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var authStateHandle: AuthStateDidChangeListenerHandle!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Firebase init
        FirebaseApp.configure()
        
        // Google Maps init
        GMSServices.provideAPIKey("AIzaSyBMDBV2OJElAvejOGaRehp-kUNF3pNjg_s")
        
        // Firebase : Check user login status, on first-time start
        if let vc = self.window?.rootViewController as? MapViewController {
            if Auth.auth().currentUser != nil {
                vc.isLaunchedUpdateUIAfterLogIn = true
            }
            else {
                vc.isLaunchedUpdateUIAfterLogOut = true
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        // Firebase : Remove auth listener
        Auth.auth().removeStateDidChangeListener(self.authStateHandle)
        
        // Map view controller : Force stop playing
        if let vc = self.window?.rootViewController as? MapViewController, vc.myLocation.isShared {
            vc.stopPlaying()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // Firebase : Add auth listener
        self.authStateHandle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            print("Firebase : auth listener user = \(String(describing: user))")
            
            // Map view controller : Force update UI
            if let vc = self.window?.rootViewController as? MapViewController {
                if user != nil {
                    vc.updateUIAfterLogIn()
                }
                else {
                    vc.updateUIAfterLogOut()
                }
            }
        })
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

