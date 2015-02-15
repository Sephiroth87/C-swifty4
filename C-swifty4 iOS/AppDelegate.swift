//
//  AppDelegate.swift
//  C-swifty4 iOS
//
//  Created by Fabio Ritrovato on 11/01/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        application.statusBarStyle = .LightContent
        return true
    }

}

