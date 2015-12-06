//
//  CIA.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 08/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

import Foundation

private struct CIAState: ComponentState {
    
    //MARK: Registers
    private var pra: UInt8 = 0xFF // Data Port Register A
    private var prb: UInt8 = 0xFF // Data Port Register B
    private var ddra: UInt8 = 0 // Data Direction Register A
    private var ddrb: UInt8 = 0 // Data Direction Register B
    private var imr: UInt8 = 0 // Interrupts Mask Register
    private var icr: UInt8 = 0 // Interrupts Control Register
    private var cra: UInt8 = 0 // Control Register A
    private var crb: UInt8 = 0 // Control Register B
    //MARK: -
    
    //MARK: Internal Registers
    private var latchA: UInt16 = 0
    private var counterA: UInt16 = 0xFFFF
    private var latchB: UInt16 = 0
    private var counterB: UInt16 = 0xFFFF
    //MARK: -
    
    //MARK: IECDevice lines for CIA2
    private var atnPin: Bool? = true
    private var clkPin = true
    private var dataPin = true
    //MARK: -
    
}

internal class CIA: Component {
    
    private var state = CIAState()
    func componentState() -> ComponentState {
        return state
    }
    
    internal weak var cpu: CPU!
    internal var crashHandler: C64CrashHandler?
   
    internal func cycle() {
        //TODO: real timer handling
        if state.cra & 0x01 != 0 {
            state.counterA = state.counterA &- 1
        }
        if state.counterA == 0 {
            state.counterA = state.latchA
            if state.cra & 0x08 != 0 {
                state.cra &= ~0x01
            }
            state.icr |= 0x01
            if state.imr & 0x01 != 0 {
                state.icr |= 0x80
                triggerInterrupt()
            }
        }
        if state.crb & 0x01 != 0 {
            state.counterB = state.counterB &- 1
        }
        if state.counterB == 0 {
            state.counterB = state.latchB
            if state.crb & 0x08 != 0 {
                state.crb &= ~0x01
            }
            state.icr |= 0x02
            if state.imr & 0x02 != 0 {
                state.icr |= 0x80
                triggerInterrupt()
            }
        }
    }
    
    internal func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case 0x02:
            state.ddra = byte
        case 0x03:
            state.ddrb = byte
        case 0x04:
            state.latchA = (state.latchA & 0xFF00) | UInt16(byte)
        case 0x05:
            state.latchA = (UInt16(byte) << 8) | (state.latchA & 0xFF);
            if state.cra & 0x01 == 0 {
                state.counterA = state.latchA
            }
        case 0x06:
            state.latchB = (state.latchB & 0xFF00) | UInt16(byte)
        case 0x07:
            state.latchB = (UInt16(byte) << 8) | (state.latchB & 0xFF);
            if state.crb & 0x01 == 0 {
                state.counterB = state.latchB
            }
        case 0x0C:
            //TODO: serial i/o
            return
        case 0x0D:
            if ((byte & 0x80) != 0) {
                state.imr |= (byte & 0x1F)
            } else {
                state.imr &= ~(byte & 0x1F)
            }
        case 0x0E:
            // bit4: force load
            if ((byte & 0x10) != 0) {
                state.counterA = state.latchA
            }
            state.cra = byte
            //TODO: more timer stuff
        case 0x0F:
            // bit4: force load
            if ((byte & 0x10) != 0) {
                state.counterB = state.latchB
            }
            state.crb = byte
            //TODO: more timer stuff
        default:
            crashHandler?("todo cia write address: " + String(position, radix: 16, uppercase: true))
        }
    }
    
    internal func readByte(position: UInt8) -> UInt8 {
        switch position {
        case 0x02:
            return state.ddra
        case 0x03:
            return state.ddrb
        case 0x04:
            return UInt8(truncatingBitPattern: state.counterA)
        case 0x05:
            return UInt8(truncatingBitPattern: state.counterA >> 8)
        case 0x06:
            return UInt8(truncatingBitPattern: state.counterB)
        case 0x07:
            return UInt8(truncatingBitPattern: state.counterB >> 8)
        case 0x0C:
            //TODO: serial i/o
            return 0
        case 0x0D:
            let value = state.icr
            state.icr = 0
            return value
        case 0x0E:
            return state.cra & ~0x10
        case 0x0F:
            return state.crb & ~0x10
        default:
            crashHandler?("todo cia read address: " + String(position, radix: 16, uppercase: true))
            return 0
        }
    }
    
    private func triggerInterrupt() {}
}

final internal class CIA1: CIA {
    
    internal weak var keyboard: Keyboard!
    internal weak var joystick2: Joystick!
    
    override init() {
        super.init()
        state.ddra = 0xFF
    }
    
    internal override func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case 0x00:
            state.pra = byte | ~state.ddra
            return
        case 0x01:
            state.prb = byte | ~state.ddrb
            return
        default:
            super.writeByte(position, byte: byte)
        }
    }
    
    internal override func readByte(position: UInt8) -> UInt8 {
        switch position {
        case 0x00:
            var joystick: UInt8 = 0xFF
            switch joystick2.xAxis {
            case .Left:
                joystick &= ~UInt8(0x04)
            case .Right:
                joystick &= ~UInt8(0x08)
            case .None:
                break
            }
            switch joystick2.yAxis {
            case .Up:
                joystick &= ~UInt8(0x01)
            case .Down:
                joystick &= ~UInt8(0x02)
            case .None:
                break
            }
            if joystick2.button == .Pressed {
                joystick &= ~UInt8(0x10)
            }
            return state.pra & joystick
        case 0x01:
            //TODO: Actually read from 0x00 because of joystick that might change bits
            return keyboard.readMatrix(state.pra) & state.prb
        default:
            return super.readByte(position)
        }
    }
    
    private override func triggerInterrupt() {
        cpu.setIRQLine()
    }
    
}

final internal class CIA2: CIA, IECDevice {
    
    internal weak var vic: VIC!
    internal weak var iec: IEC!
    
    //MARK: IECDevice
    internal var atnPin: Bool? {
        return state.atnPin
    }
    internal var clkPin: Bool {
        return state.clkPin
    }
    internal var dataPin: Bool {
        return state.dataPin
    }
    //MARK: -
    
    override init() {
        super.init()
        state.ddra = 0x3F
    }
    
    internal override func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case 0x00:
            state.pra = byte | ~state.ddra
            vic.setMemoryBank(state.pra & 0x3)
            state.atnPin = state.pra & 0x08 == 0
            state.clkPin = state.pra & 0x10 == 0
            state.dataPin = state.pra & 0x20 == 0
            iec.updatePins(self)
        default:
            super.writeByte(position, byte: byte)
        }
    }
    
    internal override func readByte(position: UInt8) -> UInt8 {
        switch position {
        case 0x00:
            return ((state.pra | ~state.ddra) & 0x3F) | (iec.clkLine ? 0x40 : 0x00) | (iec.dataLine ? 0x80 : 0x00)
        default:
            return super.readByte(position)
        }
    }
    
    func iecUpdatedLines(atnLineUpdated atnLineUpdated: Bool, clkLineUpdated: Bool, dataLineUpdated: Bool) { }
    
}
