//
//  ViewController.swift
//  C-swifty4 Mac
//
//  Created by Fabio Ritrovato on 11/01/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import Cocoa
import C64

class ViewController: NSViewController {
    
    @IBOutlet private var graphicsView: ContextBackedView!
    @IBOutlet private var playButton: NSButton!
    @IBOutlet private var stepButton: NSButton!
    @IBOutlet private var fpsLabel: NSTextField!
    
    private var startTime: CFTimeInterval = 0
    private var frames = 0

    private let c64: C64 = {
        C64(kernalData: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("kernal", ofType: nil, inDirectory:"ROM")!)!,
            basicData: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("basic", ofType: nil, inDirectory:"ROM")!)!,
            characterData: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("chargen", ofType: nil, inDirectory:"ROM")!)!)
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        c64.delegate = self
        onPlayButton(self)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.view.window?.makeFirstResponder(self)
        self.view.window?.delegate = self
    }
    
    override var acceptsFirstResponder: Bool {
        get {
            return true
        }
    }
    
    //MARK: Actions
    
    @IBAction func onPlayButton(AnyObject) {
        if c64.running {
            c64.step()
            playButton.title = "▶︎"
        } else {
            stepButton.enabled = false
            stepButton.alphaValue = 0.5
            playButton.title = "II"
            c64.run()
        }
    }
    
    @IBAction func onStepButton(AnyObject) {
        c64.step()
    }
    
    @IBAction func onDiskButton(AnyObject) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["prg", "txt"]
        panel.beginSheetModalForWindow(self.view.window!, completionHandler: { (result) -> Void in
            if let url = panel.URLs.first as? NSURL where result == NSFileHandlingPanelOKButton {
                switch String(url.pathExtension!).lowercaseString {
                case "txt":
                    self.c64.loadString(String(contentsOfURL: url, encoding: NSUTF8StringEncoding, error: nil)!)
                case "prg":
                    self.c64.loadPRGFile(NSData(contentsOfURL: url)!)
                default:
                    break
                }
            }
        })
    }
    
    override func keyDown(theEvent: NSEvent) {
        switch theEvent.keyCode {
        case 36:
            c64.pressSpecialKey(.Return)
        case 51:
            c64.pressSpecialKey(.Backspace)
        case 123:
            c64.setJoystick2XAxis(.Left)
        case 124:
            c64.setJoystick2XAxis(.Right)
        case 125:
            c64.setJoystick2YAxis(.Down)
        case 126:
            c64.setJoystick2YAxis(.Up)
        default:
            if let characters = theEvent.characters?.utf8 {
                c64.pressKey(characters[characters.startIndex])
            }
        }
    }

    override func keyUp(theEvent: NSEvent) {
        switch theEvent.keyCode {
        case 36:
            c64.releaseSpecialKey(.Return)
        case 51:
            c64.releaseSpecialKey(.Backspace)
        case 123, 124:
            c64.setJoystick2XAxis(.None)
        case 125, 126:
            c64.setJoystick2YAxis(.None)
        default:
            if let characters = theEvent.characters?.utf8 {
                c64.releaseKey(characters[characters.startIndex])
            }
        }
    }
    
    override func flagsChanged(theEvent: NSEvent) {
        if theEvent.modifierFlags & .ControlKeyMask != nil {
            c64.pressJoystick2Button()
        } else {
            c64.releaseJoystick2Button()
        }
    }
    
}

extension ViewController: NSWindowDelegate {
    
    func windowWillResize(sender: NSWindow, toSize frameSize: NSSize) -> NSSize {
        let widthDiff = frameSize.width - sender.frame.size.width
        let heightDiff = frameSize.height - sender.frame.size.height
        
        if abs(heightDiff) > abs(widthDiff) {
            let newHeight = frameSize.height
            let newWidth = ((newHeight - 22) / 235) * 420
            self.view.window?.contentAspectRatio = NSSize(width: newWidth, height: newHeight)
        } else {
            let newWidth = frameSize.width
            let newHeight = ((newWidth / 420) * 235) + 22
            self.view.window?.contentAspectRatio = NSSize(width: newWidth, height: newHeight)
        }
        return frameSize
    }

}

extension ViewController: C64Delegate {
    
    func C64VideoFrameReady(c64: C64) {
        graphicsView.setData(c64.screenBuffer())
        
        if ++frames == 60 {
            let newTime = CACurrentMediaTime()
            let time = newTime - startTime
            fpsLabel.stringValue = "\(Int(60 / time)) FPS"
            startTime = newTime
            frames = 0
        }
    }
    
    func C64DidBreak(c64: C64) {
        println(c64.debugInfo())
        
        stepButton.enabled = true
        stepButton.alphaValue = 1.0
        playButton.title = "▶︎"
    }
    
    func C64DidCrash(c64: C64) {
        
    }
    
}
