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
    // This is temporary, the emulator itself should not crash, but it's useful for missing features ATM
    // (and abort/assert/exceptions don't work well with testing...)
    func C64DidCrash(c64: C64)
}

internal typealias C64CrashHandler = (String) -> Void

final public class C64: NSObject {
    
    public var running: Bool = false
    public weak var delegate: C64Delegate?
    private var dispatchQueue: dispatch_queue_t
    
    private var breakpoints: [UInt16: Bool] = [UInt16: Bool]()
    
    private let cpu: CPU
    private let memory: C64Memory
    private let cia1: CIA1
    private let cia2: CIA2
    private let sid: SID
    private let vic: VIC
    private let keyboard: Keyboard
    private let joystick1: Joystick
    private let joystick2: Joystick
    private let iec: IEC
    public let c1541: C1541
    
    private let irqLine: Line
    
    private var cycles = 0
    private var lines = 0
    
    public init(kernalData: NSData, basicData: NSData, characterData: NSData, c1541Data: NSData) {
        if (kernalData.length != 8192 || basicData.length != 8192 || characterData.length != 4096 || c1541Data.length != 16384) {
            assertionFailure("Wrong data found");
        }
        
        cpu = CPU(pc: 0xFCE2)
        memory = C64Memory()
        cia1 = CIA1()
        cia2 = CIA2()
        sid = SID()
        vic = VIC()
        keyboard = Keyboard()
        joystick1 = Joystick()
        joystick2 = Joystick()
        iec = IEC()
        irqLine = Line()
        c1541 = C1541(c1541Data: c1541Data)
        
        memory.writeKernalData(UnsafePointer<UInt8>(kernalData.bytes))
        memory.writeBasicData(UnsafePointer<UInt8>(basicData.bytes))
        memory.writeCharacterData(UnsafePointer<UInt8>(characterData.bytes))
        
        cpu.memory = memory
        memory.cpu = cpu
        memory.cia1 = cia1
        memory.cia2 = cia2
        memory.sid = sid
        memory.vic = vic
        cia1.cpu = cpu
        cia1.keyboard = keyboard
        cia1.joystick2 = joystick2
        cia2.cpu = cpu
        cia2.vic = vic
        cia2.iec = iec
        vic.memory = memory
        
        cia1.irqLine = irqLine
        cpu.irqLine = irqLine
        irqLine.addComponents([cpu, cia1])
        
        iec.connectDevice(cia2)
        c1541.iec = iec

        dispatchQueue = dispatch_queue_create("main.loop", DISPATCH_QUEUE_SERIAL)
        
        super.init()
        
        let crashHandler: C64CrashHandler = { (reason: String) in
            print(reason)
            self.running = false
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let _ = self.delegate?.C64DidCrash(self)
            })
        }
        cpu.crashHandler = crashHandler
        cia1.crashHandler = crashHandler
        cia2.crashHandler = crashHandler
        memory.crashHandler = crashHandler
        c1541.crashHandler = crashHandler
    }
   
    @objc private func mainLoop() {
        while running {
            executeOneCycle()
            
            if cpu.state.isAtFetch && breakpoints[cpu.state.pc &- UInt16(1)] == true {
                running = false
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let _ = self.delegate?.C64DidBreak(self)
                })
            }
        }
    }
    
    private func executeOneCycle() {
        vic.cycle()
        cia1.cycle()
        cia2.cycle()
        cpu.executeInstruction()
        c1541.cycle()
        
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
    
    private func executeToNextFetch(completion: () -> Void) {
        running = false
        dispatch_async(dispatchQueue, { () -> Void in
            self.executeOneCycle()
            while !self.cpu.state.isAtFetch {
                self.executeOneCycle()
            }
            dispatch_async(dispatch_get_main_queue(), completion)
        })
    }
    
    public func run() {
        if !running {
            running = true
            dispatch_async(dispatchQueue, mainLoop)
        }
    }
    
    public func pause() {
        executeToNextFetch {}
    }
    
    public func step() {
        executeToNextFetch {
            let _ = self.delegate?.C64DidBreak(self)
        }
    }
    
    public func setBreakpoint(address: UInt16) {
        breakpoints[address] = true
    }
    
    public func removeBreakpoint(address: UInt16) {
        breakpoints[address] = false
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
    
    //MARK: Joystick
    
    public func setJoystick2XAxis(status: JoystickXAxisStatus) {
        joystick2.xAxis = status
    }
    
    public func setJoystick2YAxis(status: JoystickYAxisStatus) {
        joystick2.yAxis = status
    }
    
    public func pressJoystick2Button() {
        joystick2.button = .Pressed
    }
    
    public func releaseJoystick2Button() {
        joystick2.button = .Released
    }
    
    //MARK: Files
    
    public func saveState(completion: (NSData) -> Void) {
        let saveBlock = {
            var dictionary = [String: [String: AnyObject]]()
            dictionary["cpu"] = self.cpu.state.toDictionary()
            dictionary["cia1"] = self.cia1.state.toDictionary()
            dictionary["cia2"] = self.cia2.state.toDictionary()
            dictionary["vic"] = self.vic.state.toDictionary()
            dictionary["memory"] = self.memory.state.toDictionary()
            let data = try? NSJSONSerialization.dataWithJSONObject(dictionary, options: [])
            completion(data ?? NSData())
            self.run()
        }
        if running {
            executeToNextFetch {
                saveBlock()
                self.run()
            }
        } else {
            saveBlock()
        }
    }
    
    public func loadState(data: NSData) {
        executeToNextFetch {
            guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []), dictionary = json as? [String: [String: AnyObject]] else { return }
            guard let cpuState = dictionary["cpu"], cia1State = dictionary["cia1"], cia2state = dictionary["cia2"], vicState = dictionary["vic"], memoryState = dictionary["memory"] else { return }
            self.cpu.updateState(cpuState)
            self.cia1.updateState(cia1State)
            self.cia2.updateState(cia2state)
            self.vic.updateState(vicState)
            self.memory.updateState(memoryState)
            self.run()
        }
    }
    
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
            print("Unsupported file format")
        }
    }
    
    public func loadD64File(data: NSData) {
        c1541.insertDisk(Disk(d64Data: UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(data.bytes), count: data.length)))
    }
    
    public func loadString(string: String) {
        let string = String(string)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            for char in string.lowercaseString.characters {
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
