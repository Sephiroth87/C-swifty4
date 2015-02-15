//
//  C64.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 06/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

import Foundation

public protocol C64Delegate: class {
    func C64VideoFrameReady(c64: C64)
    func C64DidBreak(c64: C64)
}

final public class C64: NSObject {
    
    public var running: Bool = false
    public weak var delegate: C64Delegate?
    private var dispatchQueue: dispatch_queue_t
    
    private var breakpoints: [UInt16: Bool] = [UInt16: Bool]()
    
    private let cpu: CPU
    private let memory: Memory
    private let cia1: CIA1
    private let cia2: CIA2
    private let sid: SID
    private let vic: VIC
    private let keyboard: Keyboard
    
    private var cycles = 0
    private var lines = 0
    
    private var time: CFTimeInterval = 0
    private var lastTime: CFTimeInterval = 0
    private var instructions: Double = 0
    
    public init(kernalData: NSData, basicData: NSData, characterData: NSData) {
        if (kernalData.length != 8192 || basicData.length != 8192 || characterData.length != 4096) {
            assertionFailure("Wrong data found");
        }
        
        self.cpu = CPU()
        self.memory = Memory()
        self.cia1 = CIA1()
        self.cia2 = CIA2()
        self.sid = SID()
        self.vic = VIC()
        self.keyboard = Keyboard()
        
        self.memory.writeKernalData(UnsafePointer<UInt8>(kernalData.bytes))
        self.memory.writeBasicData(UnsafePointer<UInt8>(basicData.bytes))
        self.memory.writeCharacterData(UnsafePointer<UInt8>(characterData.bytes))
        
        self.cpu.memory = self.memory
        self.memory.cpu = self.cpu
        self.memory.cia1 = self.cia1
        self.memory.cia2 = self.cia2
        self.memory.sid = self.sid
        self.memory.vic = self.vic
        self.cia1.cpu = self.cpu
        self.cia1.keyboard = self.keyboard
        self.cia2.cpu = self.cpu
        self.cia2.vic = self.vic
        self.vic.memory = self.memory

        self.dispatchQueue = dispatch_queue_create("main.loop", DISPATCH_QUEUE_SERIAL)
        
        super.init()
    }
   
    @objc private func mainLoop() {
        while running {
            executeOneCycle()
            
            if cpu.isAtFetch && breakpoints[cpu.pc - 1] == true {
                running = false
            }
        }
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let _ = self.delegate?.C64DidBreak(self)
        })
    }
    
    private func executeOneCycle() {
        vic.cycle()
        cia1.cycle()
        cia2.cycle()
        cpu.executeInstruction()
        
        if ++cycles == 65 {
            cycles = 0
            ++lines
        }
        
        if lines == 263 {
            lines = 0
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                let _ = self.delegate?.C64VideoFrameReady(self)
            })
        }
    }
    
    public func run() {
        if !running {
            running = true
            dispatch_async(dispatchQueue, mainLoop)
        }
    }
    
    public func step() {
        running = false
        dispatch_async(dispatchQueue, { () -> Void in
            self.executeOneCycle()
            while !self.cpu.isAtFetch {
                self.executeOneCycle()
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let _ = self.delegate?.C64DidBreak(self)
            })
        })
    }
    
    public func setBreakpoint(address: UInt16) {
        breakpoints[address] = true
    }
    
    public func debugInfo() -> [String: String] {
        return cpu.debugInfo()
    }
    
    public func peek(address: UInt16) -> UInt8 {
        return memory.readByte(address)
    }
    
    @objc public func screenBuffer() -> UnsafePointer<UInt32> {
        return UnsafePointer<UInt32>(vic.screenBuffer)
    }
    
    //MARK: Keyboard
    
    public func pressKey(key: UInt8) {
        keyboard.pressKey(key)
    }
    
    public func pressSpecialKey(key: SpecialKey) {
        keyboard.pressSpecialKey(key)
    }
    
    public func releaseKey(key: UInt8) {
        keyboard.releaseKey(key)
    }
    
    public func releaseSpecialKey(key: SpecialKey) {
        keyboard.releaseSpecialKey(key)
    }
    
    //MARK: Files
    
    public func loadPRGFile(data: NSData) {
        if UnsafePointer<UInt8>(data.bytes)[0] == 0x01 && UnsafePointer<UInt8>(data.bytes)[1] == 0x08 {
            memory.writeRamData(UnsafePointer<UInt8>(data.subdataWithRange(NSRange(location: 2, length: data.length - 2)).bytes), position: 0x801, size: data.length - 2)
            //HACK
            let end = UInt16(0x801 + data.length - 2)
            memory.writeByte(0x2D, byte: UInt8(truncatingBitPattern: end))
            memory.writeByte(0x2E, byte: UInt8(truncatingBitPattern: end >> 8))
            memory.writeByte(0x2F, byte: UInt8(truncatingBitPattern: end))
            memory.writeByte(0x30, byte: UInt8(truncatingBitPattern: end >> 8))
            memory.writeByte(0x31, byte: UInt8(truncatingBitPattern: end))
            memory.writeByte(0x32, byte: UInt8(truncatingBitPattern: end >> 8))
        } else {
            println("Unsupported file format")
        }
    }
    
    public func loadString(string: String) {
        let string = String(string)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            for char in string.lowercaseString {
                let key = String(char).utf8[String(char).utf8.startIndex]
                dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                    if key == 10 {
                        self.keyboard.pressSpecialKey(.Return)
                    } else {
                        self.keyboard.pressKey(key)
                    }
                })
                key == 10 ? usleep(60000) : usleep(30000)
                dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                    if key == 10 {
                        self.keyboard.releaseSpecialKey(.Return)
                    } else {
                        self.keyboard.releaseKey(key)
                    }
                })
                usleep(30000)
            }
        })
    }
    
}
