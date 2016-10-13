//
//  iOSViewController.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 12/10/2016.
//  Copyright © 2016 orange in a day. All rights reserved.
//

import UIKit
import C64

final class iOSViewController: UIViewController {

    @IBOutlet fileprivate var graphicsView: ContextBackedView!
    @IBOutlet fileprivate var fpsLabel: UILabel!

    fileprivate var startTime: CFTimeInterval = 0
    fileprivate var frames = 0

    fileprivate let c64: C64 = C64(kernalData: try! Data(contentsOf: Bundle.main.url(forResource: "kernal", withExtension: nil, subdirectory:"ROM")!),
                                   basicData: try! Data(contentsOf: Bundle.main.url(forResource: "basic", withExtension: nil, subdirectory:"ROM")!),
                                   characterData: try! Data(contentsOf: Bundle.main.url(forResource: "chargen", withExtension: nil, subdirectory:"ROM")!),
                                   c1541Data: try! Data(contentsOf: Bundle.main.url(forResource: "1541", withExtension: nil, subdirectory:"ROM")!))

    override func viewDidLoad() {
        super.viewDidLoad()

        c64.delegate = self
        c64.run()
    }

}

extension iOSViewController: C64Delegate {

    func C64VideoFrameReady(_ c64: C64) {
        graphicsView.setData(c64.screenBuffer())
        frames += 1
        if frames == 60 {
            let newTime = CACurrentMediaTime()
            let time = newTime - startTime
            fpsLabel.text = "\(Int(60 / time))"
            startTime = newTime
            frames = 0
        }
    }

    func C64DidBreak(_ c64: C64) {
        dump(c64.debugInfo())
    }

    func C64DidCrash(_ c64: C64) {}
    
}
