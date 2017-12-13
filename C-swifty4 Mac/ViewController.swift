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
    
    @IBOutlet fileprivate var graphicsView: MetalView!
    @IBOutlet private var dropView: DropView!

    private var c64 = Emulator.shared.c64
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let resolution = c64.configuration.vic.resolution
        graphicsView.setTextureSize(CGSize(width: resolution.width, height: resolution.height),
                                    safeArea: c64.configuration.vic.safeArea)
        
        dropView.handleFile = handleFile
        
        Emulator.shared.frameDataHandler = graphicsView.setData
        c64.run()
    }
    

    
    override func viewWillAppear() {
        super.viewWillAppear()
        let resolution = Emulator.shared.c64.configuration.vic.resolution
        let safeArea = Emulator.shared.c64.configuration.vic.safeArea
        let size = NSSize(width: (resolution.width - safeArea.left - safeArea.right) * 2, height: (resolution.height - safeArea.top - safeArea.bottom) * 2)
        view.window?.setContentSize(size)
        view.window?.contentMinSize = size
        view.window?.contentAspectRatio = size
        view.window?.makeFirstResponder(self)
        view.window?.layoutIfNeeded()
        view.window?.center()
        
        view.window?.standardWindowButton(.closeButton)?.alphaValue = 0.0
        view.window?.standardWindowButton(.miniaturizeButton)?.alphaValue = 0.0
        view.window?.standardWindowButton(.zoomButton)?.alphaValue = 0.0
        view.addTrackingArea(NSTrackingArea(rect: view.bounds, options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect], owner: view, userInfo: nil))
    }

    override var acceptsFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup({ _ in
            view.window?.standardWindowButton(.closeButton)?.animator().alphaValue = 1.0
            view.window?.standardWindowButton(.miniaturizeButton)?.animator().alphaValue = 1.0
            view.window?.standardWindowButton(.zoomButton)?.animator().alphaValue = 1.0
        }, completionHandler: nil)
    }
    
    override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup({ _ in
            view.window?.standardWindowButton(.closeButton)?.animator().alphaValue = 0.0
            view.window?.standardWindowButton(.miniaturizeButton)?.animator().alphaValue = 0.0
            view.window?.standardWindowButton(.zoomButton)?.animator().alphaValue = 0.0
        }, completionHandler: nil)
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
        case "prg", "rw":
            c64.loadPRGFile(try! Data(contentsOf: url))
            c64.loadString("RUN\n")
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
    
    @IBAction func loadFile(_ sender: AnyObject) {
        c64.pause()
        let panel = NSOpenPanel()
        panel.allowedFileTypes = C64.supportedFileTypes
        panel.beginSheetModal(for: self.view.window!) { result in
            if let url = panel.urls.first , result.rawValue == NSFileHandlingPanelOKButton {
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
            if let url = panel.url , result.rawValue == NSFileHandlingPanelOKButton {
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
            if let url = panel.urls.first , result.rawValue == NSFileHandlingPanelOKButton {
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
            if let characters = theEvent.charactersIgnoringModifiers?.lowercased().utf8 {
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
            if let characters = theEvent.charactersIgnoringModifiers?.lowercased().utf8 {
                c64.releaseKey(characters[characters.startIndex])
            }
        }
    }
    
    override func flagsChanged(with theEvent: NSEvent) {
        if theEvent.modifierFlags.intersection(NSEvent.ModifierFlags.control) != [] {
            c64.pressJoystick2Button()
        } else {
            c64.releaseJoystick2Button()
        }
        if theEvent.modifierFlags.intersection(NSEvent.ModifierFlags.shift) != [] {
            c64.pressSpecialKey(.shift)
        } else {
            c64.releaseSpecialKey(.shift)
        }
    }
    
}
