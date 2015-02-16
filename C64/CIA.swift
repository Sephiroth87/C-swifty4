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
    private var cra: UInt8 = 0 // Control Register A
    private var crb: UInt8 = 0 // Control Register B
    //MARK: -
    
    //MARK: Internal Registers
    private var latchA: UInt16 = 0
    private var counterA: UInt16 = 0xFFFF
    //MARK: -
    
    init() {}
   
    internal func cycle() {
        //TODO: real timer handling
        if cra & 0x1 != 0 {
            counterA = counterA &- 1
        }
        if counterA == 0 {
            triggerInterrupt()
            if cra & 0x8 == 0 {
                counterA = latchA
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
            //TODO: more timer stuff
            cra = byte
        case 0x0F:
            //TODO: Timer stuff
            crb = byte
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
        case 0x0D:
            //TODO: return ICR and set it to 0
            return 0
        case 0x0E:
            return cra & ~0x10
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

