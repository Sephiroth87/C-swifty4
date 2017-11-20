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
    
    @IBOutlet fileprivate var graphicsView: MetalView!
    @IBOutlet fileprivate var fpsLabel: UILabel!
    
    fileprivate var startTime: CFTimeInterval = 0
    fileprivate var frames = 0
    
    fileprivate let c64: C64 = {
        let romConfig = C64ROMConfiguration(
            kernalData: try! Data(contentsOf: Bundle.main.url(forResource: "kernal", withExtension: nil, subdirectory:"ROM")!),
            basicData: try! Data(contentsOf: Bundle.main.url(forResource: "basic", withExtension: nil, subdirectory:"ROM")!),
            characterData: try! Data(contentsOf: Bundle.main.url(forResource: "chargen", withExtension: nil, subdirectory:"ROM")!))
        let config = C64Configuration(rom: romConfig,
                                      vic: VICConfiguration.pal,
                                      c1541: C1541Configuration(rom: C1541ROMConfiguration(c1541Data: try! Data(contentsOf: Bundle.main.url(forResource: "1541", withExtension: nil, subdirectory:"ROM")!))))
        return C64(configuration: config)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let resolution = c64.configuration.vic.resolution
        graphicsView.setTextureSize(CGSize(width: resolution.width, height: resolution.height),
                                    safeArea: c64.configuration.vic.safeArea)

        c64.delegate = self
        c64.run()
    }

}

extension ViewController: C64Delegate {
    
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
    
    func C64DidBreak(_ c64: C64) {}
    
    func C64DidCrash(_ c64: C64) {}
    
}
