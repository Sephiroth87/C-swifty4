//
//  C1541.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 17/04/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import Foundation

public protocol C1541Delegate: class {
    func C1541UpdateLedStatus(c1541: C1541, ledOn: Bool)
}

final public class C1541 {
    
    public weak var delegate: C1541Delegate?
    internal var crashHandler: C64CrashHandler? {
        didSet {
            self.cpu.crashHandler = crashHandler
        }
    }
    
    private let cpu: CPU
    private let memory: C1541Memory
    private let via1: VIA1
    private let via2: VIA2
    
    private let irqLine: Line
    
    internal weak var iec: IEC! {
        didSet {
            self.via1.iec = iec
            self.iec.connectDevice(self.via1)
        }
    }
    internal var rotating = false
    private var on: Bool = false
    private var ledOn: Bool = false
    
    private var disk: Disk?
    private var halftrack: Int = 41
    private var track: Int = 21
    private var bitOffset: UInt = 0
    private var bitCounter: Int = 0
    private var byteCounter: Int = 0
    internal var shiftRegister: UInt8 = 0
    private var syncCounter: Int = 0
    private var speedZone: Int = 0
    
    internal init(c1541Data: NSData) {
        self.cpu = CPU(pc: 0xEAA0)
        self.memory = C1541Memory()
        self.via1 = VIA1()
        self.via2 = VIA2()
        
        self.cpu.memory = self.memory
        self.memory.via1 = self.via1
        self.memory.via2 = self.via2
        self.via1.cpu = self.cpu
        self.via2.cpu = self.cpu
        
        irqLine = Line()
        cpu.irqLine = irqLine
        
        self.via1.c1541 = self
        self.via2.c1541 = self
        
        self.memory.writeC1541Data(UnsafePointer<UInt8>(c1541Data.bytes))
    }
    
    internal func cycle() {
        guard on == true else { return }
        via1.cycle()
        via2.cycle()
        cpu.executeInstruction()
        if rotating {
            if bitCounter > 0 {
                bitCounter -= 16
            } else {
                //TODO: implement read/write logic
                shiftRegister <<= 1
                let bit = (disk?.tracks[track].readBit(bitOffset) ?? 0)
                shiftRegister |= bit
                if ++bitOffset >= disk?.tracks[track].length {
                    bitOffset = 0
                }
                if bit == 0x01 {
                    if ++syncCounter >= 10 {
                        via2.pb7 = true
                    }
                } else {
                    syncCounter = 0
                    if via2.pb7 == true {
                        byteCounter = 0
                        via2.pb7 = false
                    }
                }
                if ++byteCounter == 8 {
                    if via2.cb2 && !via2.pb7 { // Read mode and no SYNC
                        if via2.ca2 { // Byte ready enabled
                            via2.ca1 = false
                            cpu.setOverflow()
                        }
                    }
                    byteCounter = 0
                } else {
                    via2.ca1 = true
                }
                bitCounter += (13 + speedZone) * 4
            }
        }
    }
    
    public func turnOn() {
        on = true
    }
    
    public func turnOff() {
        on = false
    }
    
    internal func insertDisk(disk: Disk) {
        self.disk = disk
    }
    
    internal func updateLedStatus(ledOn: Bool) {
        if ledOn != self.ledOn {
            self.ledOn = ledOn
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let _ = self.delegate?.C1541UpdateLedStatus(self, ledOn: ledOn)
            })
        }
    }
    
    internal func moveHeadUp() {
        guard on == true else { return }
        if halftrack < 84 {
            ++halftrack
            track = (halftrack + 1) / 2
        }
    }
    
    internal func moveHeadDown() {
        guard on == true else { return }
        if halftrack > 1 {
            --halftrack
            track = (halftrack + 1) / 2
        }
    }
    
    internal func setSpeedZone(speedZone: Int) {
        guard on == true else { return }
        if speedZone != self.speedZone {
            self.speedZone = speedZone
        }
    }
    
}
