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
    
    @IBOutlet fileprivate var graphicsView: ContextBackedView!
    @IBOutlet fileprivate var playButton: NSButton!
    @IBOutlet fileprivate var stepButton: NSButton!
    @IBOutlet fileprivate var fpsLabel: NSTextField!
    @IBOutlet fileprivate var driveLedLabel: NSTextField!
    
    fileprivate var startTime: CFTimeInterval = 0
    fileprivate var frames = 0

    private let c64: C64 = {
        let romConfig = C64ROMConfiguration(
            kernalData: try! Data(contentsOf: Bundle.main.url(forResource: "kernal", withExtension: nil, subdirectory:"ROM")!),
            basicData: try! Data(contentsOf: Bundle.main.url(forResource: "basic", withExtension: nil, subdirectory:"ROM")!),
            characterData: try! Data(contentsOf: Bundle.main.url(forResource: "chargen", withExtension: nil, subdirectory:"ROM")!))
        let config = C64Configuration(rom: romConfig,
                                      vic: VICConfiguration.ntsc,
                                      c1541: C1541Configuration(rom: C1541ROMConfiguration(c1541Data: try! Data(contentsOf: Bundle.main.url(forResource: "1541", withExtension: nil, subdirectory:"ROM")!))))
        return C64(configuration: config)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        c64.delegate = self
        c64.c1541.delegate = self
        c64.c1541.turnOn()
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

    @discardableResult
    public func handleFile(url: URL) -> Bool {
        var result = true
        switch String(url.pathExtension).lowercased() {
        case "txt":
            if let string = try? String(contentsOf: url, encoding: String.Encoding.utf8) {
                c64.loadString(string)
            } else {
                result = false
            }
        case "prg":
            c64.loadPRGFile(try! Data(contentsOf: url))
        case "d64":
            c64.loadD64File(try! Data(contentsOf: url))
        case "p00":
            c64.loadP00File(try! Data(contentsOf: url))
        default:
            result = false
        }
        c64.run()
        return result
    }

    //MARK: Actions

    @IBAction func onPlayButton(_ sender: AnyObject) {
        if c64.running {
            c64.step()
            playButton.title = "▶︎"
        } else {
            stepButton.isEnabled = false
            stepButton.alphaValue = 0.5
            playButton.title = "II"
            c64.run()
        }
    }
    
    @IBAction func onStepButton(_ sender: AnyObject) {
        c64.step()
    }
    
    @IBAction func onDiskButton(_ sender: AnyObject) {
        c64.pause()
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["prg", "txt", "d64", "p00"]
        panel.beginSheetModal(for: self.view.window!) { result in
            if let url = panel.urls.first , result == NSFileHandlingPanelOKButton {
                self.handleFile(url: url)
            } else {
                self.c64.run()
            }
        }
    }
    
    @IBAction func saveState(_ sender: AnyObject) {
        c64.pause()
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["cs4"]
        panel.title = "Save state"
        panel.isExtensionHidden = false
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        panel.nameFieldStringValue = formatter.string(from: Date()) + ".cs4"
        if let iCloudFolder = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            panel.directoryURL = iCloudFolder.appendingPathComponent("Documents")
        }
        panel.beginSheetModal(for: view.window!) { result in
            if let url = panel.url , result == NSFileHandlingPanelOKButton {
                self.c64.saveState { save in
                    let data = Data(save.data)
                    _ = try? data.write(to: url)
                    self.c64.run()
                }
            } else {
                self.c64.run()
            }
        }
        
    }
    
    @IBAction func loadState(_ sender: AnyObject) {
        c64.pause()
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["cs4"]
        panel.beginSheetModal(for: view.window!) { result in
            if let url = panel.urls.first , result == NSFileHandlingPanelOKButton {
                let data = try! Data(contentsOf: url)
                let bytes = Array(UnsafeBufferPointer(start: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), count: data.count))
                let save = SaveState(data: bytes)
                self.c64.loadState(save) {
                    self.c64.run()
                }
            } else {
                self.c64.run()
            }
        }
    }
    
    override func keyDown(with theEvent: NSEvent) {
        switch theEvent.keyCode {
        case 36:
            c64.pressSpecialKey(.return)
        case 51:
            c64.pressSpecialKey(.backspace)
        case 123:
            c64.setJoystick2XAxis(.left)
        case 124:
            c64.setJoystick2XAxis(.right)
        case 125:
            c64.setJoystick2YAxis(.down)
        case 126:
            c64.setJoystick2YAxis(.up)
        default:
            if let characters = theEvent.characters?.utf8 {
                c64.pressKey(characters[characters.startIndex])
            }
        }
    }

    override func keyUp(with theEvent: NSEvent) {
        switch theEvent.keyCode {
        case 36:
            c64.releaseSpecialKey(.return)
        case 51:
            c64.releaseSpecialKey(.backspace)
        case 123, 124:
            c64.setJoystick2XAxis(.none)
        case 125, 126:
            c64.setJoystick2YAxis(.none)
        default:
            if let characters = theEvent.characters?.utf8 {
                c64.releaseKey(characters[characters.startIndex])
            }
        }
    }
    
    override func flagsChanged(with theEvent: NSEvent) {
        if theEvent.modifierFlags.intersection(.control) != [] {
            c64.pressJoystick2Button()
        } else {
            c64.releaseJoystick2Button()
        }
    }
    
}

extension ViewController: NSWindowDelegate {
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        var newSize = frameSize
        newSize.width = max(newSize.width, sender.contentMinSize.width)
        newSize.height = max(newSize.height, sender.contentMinSize.height + 22)
        sender.contentAspectRatio = NSSize(width: newSize.width, height: (newSize.width / (418.0 / 235.0)) + 22.0)
        return newSize
    }

}

extension ViewController: C64Delegate {
    
    func C64VideoFrameReady(_ c64: C64) {
        graphicsView.setData(c64.screenBuffer())
        
        frames += 1
        if frames == 60 {
            let newTime = CACurrentMediaTime()
            let time = newTime - startTime
            fpsLabel.stringValue = "\(Int(60 / time)) FPS"
            startTime = newTime
            frames = 0
        }
    }
    
    func C64DidBreak(_ c64: C64) {
        print(c64.debugInfo())
        
        stepButton.isEnabled = true
        stepButton.alphaValue = 1.0
        playButton.title = "▶︎"
    }
    
    func C64DidCrash(_ c64: C64) {
        
    }
    
}

extension ViewController: C1541Delegate {
    
    func C1541UpdateLedStatus(_ c1541: C1541, ledOn: Bool) {
        driveLedLabel.stringValue = ledOn ? "🔴" : "⚪️"
    }
    
}
