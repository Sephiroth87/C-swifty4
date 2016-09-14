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
    
    @IBOutlet fileprivate var graphicsView: ContextBackedView!
    
    fileprivate let c64: C64 = {
        C64(kernalData: try! Data(contentsOf: Bundle.main.url(forResource: "kernal", withExtension: nil, subdirectory:"ROM")!),
            basicData: try! Data(contentsOf: Bundle.main.url(forResource: "basic", withExtension: nil, subdirectory:"ROM")!),
            characterData: try! Data(contentsOf: Bundle.main.url(forResource: "chargen", withExtension: nil, subdirectory:"ROM")!),
            c1541Data: try! Data(contentsOf: Bundle.main.url(forResource: "1541", withExtension: nil, subdirectory:"ROM")!))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        c64.delegate = self
        c64.run()
    }

}

extension ViewController: C64Delegate {
    
    func C64VideoFrameReady(_ c64: C64) {
        graphicsView.setData(c64.screenBuffer())
    }
    
    func C64DidBreak(_ c64: C64) {
    }
    
    func C64DidCrash(_ c64: C64) {
    }
    
}
