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

    @IBOutlet fileprivate var graphicsView: FakeMetalView!
    @IBOutlet fileprivate var fpsLabel: UILabel!

    fileprivate var startTime: CFTimeInterval = 0
    fileprivate var frames = 0

    fileprivate let c64: C64 = {
        let romConfig = C64ROMConfiguration(
            kernalData: try! Data(contentsOf: Bundle.main.url(forResource: "kernal", withExtension: nil, subdirectory:"ROM")!),
            basicData: try! Data(contentsOf: Bundle.main.url(forResource: "basic", withExtension: nil, subdirectory:"ROM")!),
            characterData: try! Data(contentsOf: Bundle.main.url(forResource: "chargen", withExtension: nil, subdirectory:"ROM")!))
        let config = C64Configuration(rom: romConfig,
                                      vic: .pal,
                                      c1541: C1541Configuration(rom: C1541ROMConfiguration(c1541Data: try! Data(contentsOf: Bundle.main.url(forResource: "1541", withExtension: nil, subdirectory:"ROM")!))))
        return C64(configuration: config)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let resolution = c64.configuration.vic.resolution
        graphicsView.setTextureSize(CGSize(width: resolution.width, height: resolution.height),
                                    safeArea: c64.configuration.vic.safeArea)

        becomeFirstResponder()

        c64.delegate = self
        c64.run()
    }

    override var canBecomeFirstResponder: Bool {
        return true
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

extension iOSViewController: UIKeyInput {

    var autocorrectionType: UITextAutocorrectionType {
        get { return .no }
        set {}
    }

    var keyboardAppearance: UIKeyboardAppearance {
        get { return .dark }
        set {}
    }

    var hasText: Bool {
        return true
    }

    func insertText(_ text: String) {
        if text == "\n" {
            c64.pressSpecialKey(.return)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
                self.c64.releaseSpecialKey(.return)
            }
        } else {
            let char = text.utf8[text.utf8.startIndex]
            c64.pressKey(char)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
                self.c64.releaseKey(char)
            }
        }
    }

    func deleteBackward() {
        c64.pressSpecialKey(.backspace)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            self.c64.releaseSpecialKey(.backspace)
        }
    }

}
