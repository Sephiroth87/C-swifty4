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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.global(qos: .default).async {
            FileManager.default.url(forUbiquityContainerIdentifier: nil)
        }
    }

}

