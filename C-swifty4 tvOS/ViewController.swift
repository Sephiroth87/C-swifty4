//
//  ViewController.swift
//  C-swifty4 tvOS
//
//  Created by Fabio Ritrovato on 15/11/2015.
//  Copyright © 2015 orange in a day. All rights reserved.
//

import UIKit
import C64

class ViewController: UIViewController {
    
    @IBOutlet private var graphicsView: ContextBackedView!
    
    private let c64: C64 = {
        C64(kernalData: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("kernal", ofType: nil, inDirectory:"ROM")!)!,
            basicData: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("basic", ofType: nil, inDirectory:"ROM")!)!,
            characterData: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("chargen", ofType: nil, inDirectory:"ROM")!)!,
            c1541Data: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("1541", ofType: nil, inDirectory:"ROM")!)!)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        c64.delegate = self
        c64.run()
    }

}

extension ViewController: C64Delegate {
    
    func C64VideoFrameReady(c64: C64) {
        graphicsView.setData(c64.screenBuffer())
    }
    
    func C64DidBreak(c64: C64) {
    }
    
    func C64DidCrash(c64: C64) {
    }
    
}
