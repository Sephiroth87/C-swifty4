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
    
    @IBOutlet fileprivate var graphicsView: ContextBackedView!
    @IBOutlet fileprivate var playButton: UIButton!
    @IBOutlet fileprivate var stepButton: UIButton!
    @IBOutlet fileprivate var pcLabel: UILabel!
    @IBOutlet fileprivate var instructionLabel: UILabel!
    @IBOutlet fileprivate var aLabel: UILabel!
    @IBOutlet fileprivate var xLabel: UILabel!
    @IBOutlet fileprivate var yLabel: UILabel!
    @IBOutlet fileprivate var spLabel: UILabel!
    @IBOutlet fileprivate var flagNLabel: UILabel!
    @IBOutlet fileprivate var flagVLabel: UILabel!
    @IBOutlet fileprivate var flagBLabel: UILabel!
    @IBOutlet fileprivate var flagDLabel: UILabel!
    @IBOutlet fileprivate var flagILabel: UILabel!
    @IBOutlet fileprivate var flagZLabel: UILabel!
    @IBOutlet fileprivate var flagCLabel: UILabel!
    @IBOutlet fileprivate var keyboardTextField: UITextField!

    fileprivate let c64: C64 = {
        C64(kernalData: try! Data(contentsOf: Bundle.main.url(forResource: "kernal", withExtension: nil, subdirectory:"ROM")!),
            basicData: try! Data(contentsOf: Bundle.main.url(forResource: "basic", withExtension: nil, subdirectory:"ROM")!),
            characterData: try! Data(contentsOf: Bundle.main.url(forResource: "chargen", withExtension: nil, subdirectory:"ROM")!),
            c1541Data: try! Data(contentsOf: Bundle.main.url(forResource: "1541", withExtension: nil, subdirectory:"ROM")!))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        c64.delegate = self
        onPlayButton()
    }
    
    override var canBecomeFirstResponder: Bool {
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FilePickerSegue" {
            if let filePicker = (segue.destination as? UINavigationController)?.topViewController as? FilePickerViewController {
                filePicker.completionBlock = { (url) -> Void in
                    switch url.pathExtension.lowercased() {
                    case "txt":
                        if let string = try? String(contentsOf: url, encoding: String.Encoding.utf8) {
                            self.c64.loadString(string)
                        }
                    case "prg":
                        self.c64.loadPRGFile(NSData(contentsOf: url as URL)! as Data)
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
            playButton.setTitle("▶︎", for: UIControlState())
        } else {
            stepButton.isEnabled = false
            stepButton.alpha = 0.5
            playButton.setTitle("II", for: UIControlState())
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
        let alert = UIAlertController(title: "Peek", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) -> Void in
            textField.keyboardType = .namePhonePad
        }
        let action = UIAlertAction(title: "Ok", style: .default) { (action) -> Void in
            if let string = alert.textFields?[0].text{
                let scanner = Scanner(string: string)
                var address: UInt32 = 0
                if scanner.scanHexInt32(&address) {
                    let outAlert = UIAlertController(title: String(format: "%02x", self.c64.peek(UInt16(truncatingBitPattern: address))), message: nil, preferredStyle: .alert)
                    outAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(outAlert, animated: true, completion: nil)
                }
            }
        }
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onKeyboardButton() {
        keyboardTextField.superview?.isUserInteractionEnabled = true
        keyboardTextField.becomeFirstResponder()
    }
    
    @IBAction func onDiskButton() {
        
    }
    
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        keyboardTextField.superview?.isUserInteractionEnabled = false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty {
            c64.pressSpecialKey(.backspace)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(70000000) / Double(NSEC_PER_SEC)) { () -> Void in
                self.c64.releaseSpecialKey(.backspace)
            }
        } else {
            let char = string.utf8[string.utf8.startIndex]
            c64.pressKey(char)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(70000000) / Double(NSEC_PER_SEC)) { () -> Void in
                self.c64.releaseKey(char)
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        c64.pressSpecialKey(.return)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(70000000) / Double(NSEC_PER_SEC)) { () -> Void in
            self.c64.releaseSpecialKey(.return)
        }
        return false
    }
    
}

extension ViewController: C64Delegate {
    
    func C64VideoFrameReady(_ c64: C64) {
        graphicsView.setData(c64.screenBuffer())
    }
    
    func C64DidBreak(_ c64: C64) {
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
        
        stepButton.isEnabled = true
        stepButton.alpha = 1.0
        playButton.setTitle("▶︎", for: UIControlState())
        
        keyboardTextField.resignFirstResponder()
    }
    
    func C64DidCrash(_ c64: C64) {
        
    }
    
}

