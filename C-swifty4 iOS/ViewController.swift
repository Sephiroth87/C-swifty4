//
//  ViewController.swift
//  C-swifty4 iOS
//
//  Created by Fabio Ritrovato on 11/01/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import UIKit
import C64

class ViewController: UIViewController {
    
    @IBOutlet private var graphicsView: ContextBackedView!
    @IBOutlet private var playButton: UIButton!
    @IBOutlet private var stepButton: UIButton!
    @IBOutlet private var pcLabel: UILabel!
    @IBOutlet private var instructionLabel: UILabel!
    @IBOutlet private var aLabel: UILabel!
    @IBOutlet private var xLabel: UILabel!
    @IBOutlet private var yLabel: UILabel!
    @IBOutlet private var spLabel: UILabel!
    @IBOutlet private var flagNLabel: UILabel!
    @IBOutlet private var flagVLabel: UILabel!
    @IBOutlet private var flagBLabel: UILabel!
    @IBOutlet private var flagDLabel: UILabel!
    @IBOutlet private var flagILabel: UILabel!
    @IBOutlet private var flagZLabel: UILabel!
    @IBOutlet private var flagCLabel: UILabel!
    @IBOutlet private var keyboardTextField: UITextField!

    private let c64: C64 = {
        C64(kernalData: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("kernal", ofType: nil, inDirectory:"ROM")!)!,
            basicData: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("basic", ofType: nil, inDirectory:"ROM")!)!,
            characterData: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("chargen", ofType: nil, inDirectory:"ROM")!)!)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        c64.delegate = self
        onPlayButton()
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    func clearDebugInfo() {
        pcLabel.text = "----"
        instructionLabel.text = "Running"
        aLabel.text = "--"
        xLabel.text = "--"
        yLabel.text = "--"
        spLabel.text = "--"
        flagNLabel.text = "-"
        flagVLabel.text = "-"
        flagBLabel.text = "-"
        flagDLabel.text = "-"
        flagILabel.text = "-"
        flagZLabel.text = "-"
        flagCLabel.text = "-"
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "FilePickerSegue" {
            if let filePicker = segue.destinationViewController.topViewController as? FilePickerViewController {
                filePicker.completionBlock = { (url) -> Void in
                    switch String(url.pathExtension!).lowercaseString {
                    case "txt":
                        self.c64.loadString(String(contentsOfURL: url, encoding: NSUTF8StringEncoding, error: nil)!)
                    case "prg":
                        self.c64.loadPRGFile(NSData(contentsOfURL: url)!)
                    default:
                        break
                    }
                }
            }
        }
    }
    
    //MARK: Actions
    
    @IBAction func onPlayButton() {
        if c64.running {
            c64.step()
            playButton.setTitle("▶︎", forState: .Normal)
        } else {
            stepButton.enabled = false
            stepButton.alpha = 0.5
            playButton.setTitle("II", forState: .Normal)
            clearDebugInfo()
            c64.run()
        }
    }
    
    @IBAction func onStepButton() {
        c64.step()
    }
    
    @IBAction func onPeekButton() {
        if c64.running {
            onPlayButton()
        }
        let alert = UIAlertController(title: "Peek", message: nil, preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.keyboardType = .NamePhonePad
        }
        let action = UIAlertAction(title: "Ok", style: .Default) { (action) -> Void in
            let scanner = NSScanner(string: (alert.textFields as! [UITextField])[0].text)
            var address: UInt32 = 0
            if scanner.scanHexInt(&address) {
                let outAlert = UIAlertController(title: String(format: "%02x", self.c64.peek(UInt16(truncatingBitPattern: address))), message: nil, preferredStyle: .Alert)
                outAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                self.presentViewController(outAlert, animated: true, completion: nil)
            }
        }
        alert.addAction(action)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func onKeyboardButton() {
        keyboardTextField.superview?.userInteractionEnabled = true
        keyboardTextField.becomeFirstResponder()
    }
    
    @IBAction func onDiskButton() {
        
    }
    
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(textField: UITextField) {
        keyboardTextField.superview?.userInteractionEnabled = false
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if count(string) == 0 {
            c64.pressSpecialKey(.Backspace)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 70000000), dispatch_get_main_queue()) { () -> Void in
                self.c64.releaseSpecialKey(.Backspace)
            }
        } else {
            let char = string.utf8[string.utf8.startIndex]
            c64.pressKey(char)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 70000000), dispatch_get_main_queue()) { () -> Void in
                self.c64.releaseKey(char)
            }
        }
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        c64.pressSpecialKey(.Return)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 70000000), dispatch_get_main_queue()) { () -> Void in
            self.c64.releaseSpecialKey(.Return)
        }
        return false
    }
    
}

extension ViewController: C64Delegate {
    
    func C64VideoFrameReady(c64: C64) {
        graphicsView.setData(c64.screenBuffer())
    }
    
    func C64DidBreak(c64: C64) {
        let debugInfo = c64.debugInfo()
        pcLabel.text = debugInfo["pc"]
        instructionLabel.text = debugInfo["description"]
        aLabel.text = debugInfo["a"]
        xLabel.text = debugInfo["x"]
        yLabel.text = debugInfo["y"]
        spLabel.text = debugInfo["sp"]
        flagNLabel.text = debugInfo["sr.n"]
        flagVLabel.text = debugInfo["sr.v"]
        flagBLabel.text = debugInfo["sr.b"]
        flagDLabel.text = debugInfo["sr.d"]
        flagILabel.text = debugInfo["sr.i"]
        flagZLabel.text = debugInfo["sr.z"]
        flagCLabel.text = debugInfo["sr.c"]
        
        stepButton.enabled = true
        stepButton.alpha = 1.0
        playButton.setTitle("▶︎", forState: .Normal)
        
        keyboardTextField.resignFirstResponder()
    }
    
    func C64DidCrash(c64: C64) {
        
    }
    
}

