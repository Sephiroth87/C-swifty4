//
//  Emulator.swift
//  C-swifty4 Mac
//
//  Created by Fabio on 12/12/2017.
//  Copyright © 2017 orange in a day. All rights reserved.
//

import Cocoa
import C64

class Emulator: NSObject {
    
    lazy private(set) var c64: C64 = {
        let romConfig = C64ROMConfiguration(
            kernalData: try! Data(contentsOf: Bundle.main.url(forResource: "kernal", withExtension: nil, subdirectory:"ROM")!),
            basicData: try! Data(contentsOf: Bundle.main.url(forResource: "basic", withExtension: nil, subdirectory:"ROM")!),
            characterData: try! Data(contentsOf: Bundle.main.url(forResource: "chargen", withExtension: nil, subdirectory:"ROM")!))
        let config = C64Configuration(rom: romConfig,
                                      vic: .pal,
                                      c1541: C1541Configuration(rom: C1541ROMConfiguration(c1541Data: try! Data(contentsOf: Bundle.main.url(forResource: "1541", withExtension: nil, subdirectory:"ROM")!))))
        let c64 = C64(configuration: config)
        c64.delegate = self
        c64.c1541.delegate = self
        c64.c1541.turnOn()
        return c64
    }()
    
    public static let shared = Emulator()
    public var frameDataHandler: ((UnsafePointer<UInt32>) -> ())?
    @objc dynamic public var fps: Int = 0
    @objc dynamic public var running = false
    @objc dynamic public var debugString = ""
    @objc dynamic public var driveLed = false
    fileprivate var startTime: CFTimeInterval = 0
    fileprivate var frames = 0

}

extension Emulator: C64Delegate {
    
    func C64VideoFrameReady(_ c64: C64) {
        frameDataHandler?(c64.screenBuffer())
        
        frames += 1
        if frames == 60 {
            let newTime = CACurrentMediaTime()
            let time = newTime - startTime
            fps = Int(60 / time)
            startTime = newTime
            frames = 0
        }
    }
    
    func C64DidRun(_ c64: C64) {
        debugString = ""
        running = true
    }
    
    func C64DidBreak(_ c64: C64) {
        debugString = c64.debugInfo()["cpu"]!
        running = false
    }
    
    func C64DidCrash(_ c64: C64) {
        
    }
}

extension Emulator: C1541Delegate {
    
    func C1541UpdateLedStatus(_ c1541: C1541, ledOn: Bool) {
        driveLed = ledOn
    }
}
