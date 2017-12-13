//
//  C64.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 06/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

import Foundation

public protocol C64Delegate: class {
    func C64VideoFrameReady(_ c64: C64)
    func C64DidRun(_ c64: C64)
    func C64DidBreak(_ c64: C64)
    // This is temporary, the emulator itself should not crash, but it's useful for missing features ATM
    // (and abort/assert/exceptions don't work well with testing...)
    func C64DidCrash(_ c64: C64)
}

public struct C64ROMConfiguration {

    let kernalData: Data
    let basicData: Data
    let characterData: Data

    public init(kernalData: Data, basicData: Data, characterData: Data) {
        self.kernalData = kernalData
        self.basicData = basicData
        self.characterData = characterData
    }

}

public struct C64Configuration {

    public var rom: C64ROMConfiguration
    public var vic: VICConfiguration
    public var c1541: C1541Configuration

    public init(rom: C64ROMConfiguration, vic: VICConfiguration, c1541: C1541Configuration) {
        self.rom = rom
        self.vic = vic
        self.c1541 = c1541
    }

}

internal typealias C64BreakpointHandler = () -> Void
internal typealias C64CrashHandler = (String) -> Void

final public class C64 {
    
    public static let supportedFileTypes = ["prg", "txt", "d64", "p00", "rw"]

    public let configuration: C64Configuration
    public var running: Bool = false
    public weak var delegate: C64Delegate?
    private var dispatchQueue: DispatchQueue
    
    private var breakpoints: [UInt16: C64BreakpointHandler] = [UInt16: C64BreakpointHandler]()
    
    internal let cpu = CPU(pc: 0xFCE2)
    internal let memory = C64Memory()
    internal let cia1 = CIA1()
    internal let cia2 = CIA2()
    internal let sid = SID()
    internal let vic: VIC
    private let keyboard = Keyboard()
    private let joystick1 = Joystick()
    private let joystick2 = Joystick()
    private let iec = IEC()
    public let c1541: C1541
    
    private let irqLine = Line()
    private let nmiLine = Line()
    private let rdyLine = Line()

    private var cycles: UInt8 = 0
    private var lines: UInt16 = 0
    
    public init(configuration: C64Configuration) {
        if configuration.rom.kernalData.count != 8192 ||
            configuration.rom.basicData.count != 8192 ||
            configuration.rom.characterData.count != 4096 {
            assertionFailure("Wrong data found");
        }
        self.configuration = configuration

        vic = VIC(configuration: configuration.vic)
        c1541 = C1541(configuration: configuration.c1541)
        
        memory.writeKernalData(configuration.rom.kernalData)
        memory.writeBasicData(configuration.rom.basicData)
        memory.writeCharacterData(configuration.rom.characterData)
        
        cpu.memory = memory
        memory.cpu = cpu
        memory.cia1 = cia1
        memory.cia2 = cia2
        memory.sid = sid
        memory.vic = vic
        cia1.keyboard = keyboard
        cia1.joystick2 = joystick2
        cia2.vic = vic
        cia2.iec = iec
        vic.memory = memory
        
        cia1.interruptLine = irqLine
        cpu.irqLine = irqLine
        vic.irqLine = irqLine
        irqLine.addComponents([cpu, cia1, vic])
        
        cia2.interruptLine = nmiLine
        cpu.nmiLine = nmiLine
        nmiLine.addComponents([cpu, cia2])
        
        cpu.rdyLine = rdyLine
        vic.rdyLine = rdyLine
        rdyLine.addComponents([vic])
        
        iec.connectDevice(cia2)
        c1541.iec = iec

        dispatchQueue = DispatchQueue(label: "main.loop", attributes: [])

        let crashHandler: C64CrashHandler = { (reason: String) in
            print(reason)
            self.running = false
            DispatchQueue.main.async {
                let _ = self.delegate?.C64DidCrash(self)
            }
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
            
            if cpu.state.isAtFetch, let bh = breakpoints[cpu.state.pc &- UInt16(1)] {
                running = false
                DispatchQueue.main.async {
                    bh()
                    self.delegate?.C64DidBreak(self)
                }
            }
        }
    }
    
    private func executeOneCycle() {
        vic.cycle()
        cia1.cycle()
        cia2.cycle()
        cpu.executeInstruction()
        c1541.cycle()
        
        cycles += 1
        if cycles == vic.configuration.cyclesPerRaster {
            cycles = 0
            lines += 1
        }
        
        if lines == vic.configuration.totalLines {
            lines = 0
            DispatchQueue.main.async {
                let _ = self.delegate?.C64VideoFrameReady(self)
            }
        }
    }
    
    private func executeToNextFetch(_ completion: @escaping () -> Void) {
        running = false
        dispatchQueue.async(execute: { () -> Void in
            self.executeOneCycle()
            while !self.cpu.state.isAtFetch {
                self.executeOneCycle()
            }
            DispatchQueue.main.async(execute: completion)
        })
    }
    
    public func run() {
        if !running {
            running = true
            dispatchQueue.async(execute: mainLoop)
            self.delegate?.C64DidRun(self)
        }
    }
    
    public func pause() {
        if running {
            executeToNextFetch {
                self.delegate?.C64DidBreak(self)
            }
        }
    }
    
    public func step() {
        executeToNextFetch {
            self.delegate?.C64DidBreak(self)
        }
    }
    
    public func setBreakpoint(at address: UInt16, handler: (()->Void)?) {
        breakpoints[address] = handler
    }
    
    public func debugInfo() -> [String: String] {
        return ["cpu": cpu.state.description + " " + cpu.debugInfo()["description"]!]
    }
    
    public func peek(_ address: UInt16) -> UInt8 {
        return memory.readByte(address)
    }
    
    @objc public func screenBuffer() -> UnsafePointer<UInt32> {
        return UnsafePointer<UInt32>(vic.screenBuffer)
    }
    
    //MARK: Keyboard
    
    public func pressKey(_ key: UInt8) {
        keyboard.pressKey(key)
    }
    
    public func pressSpecialKey(_ key: SpecialKey) {
        keyboard.pressSpecialKey(key)
    }
    
    public func releaseKey(_ key: UInt8) {
        keyboard.releaseKey(key)
    }
    
    public func releaseSpecialKey(_ key: SpecialKey) {
        keyboard.releaseSpecialKey(key)
    }
    
    //MARK: Joystick
    
    public func setJoystick2XAxis(_ status: JoystickXAxisStatus) {
        joystick2.xAxis = status
    }
    
    public func setJoystick2YAxis(_ status: JoystickYAxisStatus) {
        joystick2.yAxis = status
    }
    
    public func pressJoystick2Button() {
        joystick2.button = .pressed
    }
    
    public func releaseJoystick2Button() {
        joystick2.button = .released
    }
    
    //MARK: Files
    
    public func saveState(_ completion: @escaping (SaveState) -> Void) {
        let saveBlock = {
            completion(SaveState(c64: self))
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
    
    public func loadState(_ saveState: SaveState, completion: @escaping () -> Void) {
        let running = self.running
        executeToNextFetch {
            self.cpu.state = saveState.cpuState
            self.memory.state = saveState.memoryState
            self.cia1.state = saveState.cia1State
            self.cia2.state = saveState.cia2State
            self.vic.state = saveState.vicState
            completion()
            if running {
                self.run()
            }
        }
    }
    
    public func loadPRGFile(_ data: Data) {
        if data[0] == 0x01 && data[1] == 0x08 {
            memory.writeRamData(data.subdata(in: data.startIndex.advanced(by: 2)..<data.endIndex), position: 0x801, size: data.count - 2)
        } else {
            print("Unsupported file format")
        }
    }
    
    public func loadP00File(_ data: Data) {
        loadPRGFile(data.subdata(in: data.startIndex.advanced(by: 0x1A)..<data.endIndex))
    }
    
    public func loadD64File(_ data: Data) {
        c1541.insertDisk(Disk(d64Data: UnsafeBufferPointer<UInt8>(start: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), count: data.count)))
    }
    
    public func loadString(_ string: String) {
        let string = String(string)
        DispatchQueue.global(qos: .default).async {
            for char in string.lowercased() {
                let key = String(char).utf8[String(char).utf8.startIndex]
                DispatchQueue.main.sync(execute: { () -> Void in
                    if key == 10 {
                        self.keyboard.pressSpecialKey(.return)
                    } else {
                        self.keyboard.pressKey(key)
                    }
                })
                if key == 10 {
                    _ = usleep(60000)
                } else {
                    _ = usleep(30000)
                }
                DispatchQueue.main.sync {
                    if key == 10 {
                        self.keyboard.releaseSpecialKey(.return)
                    } else {
                        self.keyboard.releaseKey(key)
                    }
                }
                _ = usleep(30000)
            }
        }
    }
    
}
