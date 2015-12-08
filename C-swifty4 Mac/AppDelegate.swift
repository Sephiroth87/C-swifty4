//
//  AppDelegate.swift
//  C-swifty4 Mac
//
//  Created by Fabio Ritrovato on 11/01/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        dispatch_async(dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)
        }
    }

}

