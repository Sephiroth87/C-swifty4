//
//  CIA.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 08/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

import Foundation

internal class CIA {
    
    internal weak var cpu: CPU!
    internal var crashHandler: C64CrashHandler?
    
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
    
    init() {}
   
    internal func cycle() {
        //TODO: real timer handling
        if cra & 0x01 != 0 {
            counterA = counterA &- 1
        }
        if counterA == 0 {
            counterA = latchA
            if cra & 0x08 != 0 {
                cra &= ~0x01
            }
            icr |= 0x01
            if imr & 0x01 != 0 {
                icr |= 0x80
                triggerInterrupt()
            }
        }
        if crb & 0x01 != 0 {
            counterB = counterB &- 1
        }
        if counterB == 0 {
            counterB = latchB
            if crb & 0x08 != 0 {
                crb &= ~0x01
            }
            icr |= 0x02
            if imr & 0x02 != 0 {
                icr |= 0x80
                triggerInterrupt()
            }
        }
    }
    
    internal func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case 0x02:
            ddra = byte
        case 0x03:
            ddrb = byte
        case 0x04:
            latchA = (latchA & 0xFF00) | UInt16(byte)
        case 0x05:
            latchA = (UInt16(byte) << 8) | (latchA & 0xFF);
            if cra & 0x01 == 0 {
                counterA = latchA
            }
        case 0x06:
            latchB = (latchB & 0xFF00) | UInt16(byte)
        case 0x07:
            latchB = (UInt16(byte) << 8) | (latchB & 0xFF);
            if crb & 0x01 == 0 {
                counterB = latchB
            }
        case 0x0C:
            //TODO: serial i/o
            return
        case 0x0D:
            if ((byte & 0x80) != 0) {
                imr |= (byte & 0x1F)
            } else {
                imr &= ~(byte & 0x1F)
            }
        case 0x0E:
            // bit4: force load
            if ((byte & 0x10) != 0) {
                counterA = latchA
            }
            cra = byte
            //TODO: more timer stuff
        case 0x0F:
            // bit4: force load
            if ((byte & 0x10) != 0) {
                counterB = latchB
            }
            crb = byte
            //TODO: more timer stuff
        default:
            crashHandler?("todo cia write address: " + String(position, radix: 16, uppercase: true))
        }
    }
    
    internal func readByte(position: UInt8) -> UInt8 {
        switch position {
        case 0x02:
            return ddra
        case 0x03:
            return ddrb
        case 0x04:
            return UInt8(truncatingBitPattern: counterA)
        case 0x05:
            return UInt8(truncatingBitPattern: counterA >> 8)
        case 0x06:
            return UInt8(truncatingBitPattern: counterB)
        case 0x07:
            return UInt8(truncatingBitPattern: counterB >> 8)
        case 0x0C:
            //TODO: serial i/o
            return 0
        case 0x0D:
            let value = icr
            icr = 0
            return value
        case 0x0E:
            return cra & ~0x10
        case 0x0F:
            return crb & ~0x10
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
        ddra = 0xFF
    }
    
    internal override func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case 0x00:
            pra = byte | ~ddra
            return
        case 0x01:
            prb = byte | ~ddrb
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
            return pra & joystick
        case 0x01:
            //TODO: Actually read from 0x00 because of joystick that might change bits
            return keyboard.readMatrix(pra) & prb
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
    internal var atnPin: Bool? = true
    internal var clkPin = true
    internal var dataPin = true
    //MARK: -
    
    override init() {
        super.init()
        ddra = 0x3F
    }
    
    internal override func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case 0x00:
            pra = byte | ~ddra
            vic.setMemoryBank(pra & 0x3)
            atnPin = pra & 0x08 == 0
            clkPin = pra & 0x10 == 0
            dataPin = pra & 0x20 == 0
            iec.updatePins(self)
        default:
            super.writeByte(position, byte: byte)
        }
    }
    
    internal override func readByte(position: UInt8) -> UInt8 {
        switch position {
        case 0x00:
            return ((pra | ~ddra) & 0x3F) | (iec.clkLine ? 0x40 : 0x00) | (iec.dataLine ? 0x80 : 0x00)
        default:
            return super.readByte(position)
        }
    }
    
    func iecUpdatedLines(atnLineUpdated atnLineUpdated: Bool, clkLineUpdated: Bool, dataLineUpdated: Bool) { }
    
}
