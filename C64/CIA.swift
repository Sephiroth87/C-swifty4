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
    
    //MARK: Registers
    private var pra: UInt8 = 0xFF // Data Port Register A
    private var prb: UInt8 = 0xFF // Data Port Register B
    private var ddra: UInt8 = 0 // Data Direction Register A
    private var ddrb: UInt8 = 0 // Data Direction Register B
    private var imr: UInt8 = 0 // Interrupts Mask Register
    private var craStart = false // Control Register A Bit 0
    private var craPBOn = false // Control Register A Bit 1
    private var craOutMode = false // Control Register A Bit 2
    private var craRunMode = false // Control Register A Bit 3
    private var craInMode = false // Control Register A Bit 5
    private var craSPMode = false // Control Register A Bit 6
    private var craTODIn = false // Control Register A Bit 7
    private var crbStart = false // Control Register B Bit 0
    private var crbPBOn = false // Control Register B Bit 1
    private var crbOutMode = false // Control Register B Bit 2
    private var crbRunMode = false // Control Register B Bit 3
    private var crbInMode1 = false // Control Register B Bit 5
    private var crbInMode2 = false // Control Register B Bit 6
    private var crbAlarm = false // Control Register B Bit 7
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
        if craStart {
            counterA = counterA &- 1
        }
        if counterA == 0 {
            triggerInterrupt()
            counterA = latchA
        }
        if crbStart {
            counterB = counterB &- 1
        }
        if counterB == 0 {
            triggerInterrupt()
            counterB = latchB
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
            if !craStart {
                counterA = latchA
            }
        case 0x06:
            latchB = (latchB & 0xFF00) | UInt16(byte)
        case 0x07:
            latchB = (UInt16(byte) << 8) | (latchB & 0xFF);
            if !crbStart {
                counterB = latchB
            }
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
            craStart = byte & 0x01 != 0
            craPBOn = byte & 0x02 != 0
            craOutMode = byte & 0x04 != 0
            craRunMode = byte & 0x08 != 0
            craInMode = byte & 0x20 != 0
            craSPMode = byte & 0x40 != 0
            craTODIn = byte & 0x80 != 0
            //TODO: more timer stuff
        case 0x0F:
            // bit4: force load
            if ((byte & 0x10) != 0) {
                counterB = latchB
            }
            crbStart = byte & 0x01 != 0
            crbPBOn = byte & 0x02 != 0
            crbOutMode = byte & 0x04 != 0
            crbRunMode = byte & 0x08 != 0
            crbInMode1 = byte & 0x20 != 0
            crbInMode2 = byte & 0x40 != 0
            crbAlarm = byte & 0x80 != 0
            //TODO: more timer stuff
        default:
            println("todo cia write address: " + String(position, radix: 16, uppercase: true))
            abort()
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
        case 0x0D:
            //TODO: return ICR and set it to 0
            return 0
        case 0x0E:
            return (craStart ? 0x01 : 0) | (craPBOn ? 0x02 : 0) | (craOutMode ? 0x04 : 0) | (craRunMode ? 0x08 : 0) | (craInMode ? 0x20 : 0) | (craSPMode ? 0x40 : 0) | (craTODIn ? 0x80 : 0)
        case 0x0F:
            return (crbStart ? 0x01 : 0) | (crbPBOn ? 0x02 : 0) | (crbOutMode ? 0x04 : 0) | (crbRunMode ? 0x08 : 0) | (crbInMode1 ? 0x20 : 0) | (crbInMode2 ? 0x40 : 0) | (crbAlarm ? 0x80 : 0)
        default:
            println("todo cia read address: " + String(position, radix: 16, uppercase: true))
            abort()
        }
    }
    
    private func triggerInterrupt() {}
}

final internal class CIA1: CIA {
    
    internal weak var keyboard: Keyboard!
    
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
            //TODO: Real joystick
            return 0xFF
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

final internal class CIA2: CIA {
    
    internal weak var vic: VIC!
    
    override init() {
        super.init()
        ddra = 0x3F
    }
    
    internal override func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case 0x00:
            pra = byte | ~ddra
            vic.setMemoryBank(pra & 0x3)
            // VIC + IEC stuff
        default:
            super.writeByte(position, byte: byte)
        }
    }
    
    internal override func readByte(position: UInt8) -> UInt8 {
        switch position {
        case 0x00:
            //TODO: implement bit 7-8
            return (pra | ~ddra) & 0x3F
        default:
            return super.readByte(position)
        }
    }
}

