//
//  DebugViewController.swift
//  C-swifty4 Mac
//
//  Created by Fabio on 12/12/2017.
//  Copyright © 2017 orange in a day. All rights reserved.
//

import Cocoa

class DebugViewController: NSViewController {
    
    @objc dynamic private var emulator = Emulator.shared

    override func viewWillAppear() {
        super.viewWillAppear()
        
        guard let emulatorWindow = NSApplication.shared.mainWindow else { return }
        
        emulatorWindow.addChildWindow(view.window!, ordered: .above)
        var frame = view.window!.frame
        frame.origin.x = emulatorWindow.frame.midX - frame.size.width / 2.0
        frame.origin.y = emulatorWindow.frame.origin.y - frame.size.height - 20.0
        view.window!.setFrame(frame, display: true)
    }
    
    //MARK: Actions
    
    @IBAction private func onPlayButton(_ sender: AnyObject) {
        emulator.c64.run()
    }
    
    @IBAction private func onPauseButton(_ sender: AnyObject) {
        emulator.c64.pause()
    }
    
    @IBAction func onStepButton(_ sender: AnyObject) {
        emulator.c64.step()
    }
    
    @IBAction func onStepFrameButton(_ sender: AnyObject) {
        emulator.c64.stepFrame()
    }
    
}
