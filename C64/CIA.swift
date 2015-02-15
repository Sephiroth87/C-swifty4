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
    
    //MARK: Constants
    private let kDataPortRegisterAAddress: UInt8 = 0x00
    private let kDataPortRegisterBAddress: UInt8 = 0x01
    private let kDataDirectionRegisterAAddress: UInt8 = 0x02
    private let kDataDirectionRegisterBAddress: UInt8 = 0x03
    private let kTimerALowAddress: UInt8 = 0x04
    private let kTimerAHighAddress: UInt8 = 0x05
    private let kInterruptControlRegisterAddress: UInt8 = 0x0D
    private let kControlRegisterAAddress: UInt8 = 0x0E
    private let kControlRegisterBAddress: UInt8 = 0x0F
    //MARK: -
    
    //MARK: Registers
    private var PRA: UInt8 = 0xFF
    private var PRB: UInt8 = 0xFF
    private var DDRA: UInt8 = 0
    private var DDRB: UInt8 = 0
    private var IMR: UInt8 = 0
    private var CRA: UInt8 = 0
    private var CRB: UInt8 = 0
    
    private var latchA: UInt16 = 0
    private var counterA: UInt16 = 0xFFFF
    //MARK: -
    
    init() {}
   
    internal func cycle() {
        //TODO: real timer handling
        if CRA & 0x1 != 0 {
            counterA = counterA &- 1
        }
        if counterA == 0 {
            triggerInterrupt()
            if CRA & 0x8 == 0 {
                counterA = latchA
            }
        }
    }
    
    internal func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case kTimerALowAddress:
            latchA = (latchA & 0xFF00) | UInt16(byte)
        case kTimerAHighAddress:
            latchA = (UInt16(byte) << 8) | (latchA & 0xFF);
        case kInterruptControlRegisterAddress:
            if ((byte & 0x80) != 0) {
                IMR |= (byte & 0x1F)
            } else {
                IMR &= ~(byte & 0x1F)
            }
        case kControlRegisterAAddress:
            // bit4: force load
            if ((byte & 0x10) != 0) {
                counterA = latchA
            }
            //TODO: more timer stuff
            CRA = byte
        case kControlRegisterBAddress:
            //TODO: Timer stuff
            CRB = byte
        default:
            println("todo cia write address: " + String(position, radix: 16, uppercase: true))
            abort()
        }
    }
    
    internal func readByte(position: UInt8) -> UInt8 {
        switch position {
        case kInterruptControlRegisterAddress:
            //TODO: return ICR and set it to 0
            return 0
        case kControlRegisterAAddress:
            return CRA & ~0x10
        default:
            println("todo cia read address: " + String(position, radix: 16, uppercase: true))
            abort()
        }
    }
    
    private func triggerInterrupt() {}
}

final internal class CIA1: CIA {
    
    internal weak var keyboard: Keyboard!
    
    internal override func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case kDataPortRegisterAAddress:
            PRA = byte | ~DDRA
            return
        case kDataPortRegisterBAddress:
            PRB = byte | ~DDRB
            return
        case kDataDirectionRegisterAAddress:
            DDRA = byte
        case kDataDirectionRegisterBAddress:
            DDRB = byte
        default:
            super.writeByte(position, byte: byte)
        }
    }
    
    internal override func readByte(position: UInt8) -> UInt8 {
        switch position {
        case kDataPortRegisterAAddress:
            //TODO: Real joystick
            return 0xFF
        case kDataPortRegisterBAddress:
            //TODO: Actually read from kDataPortRegisterAAddress because of joystick that might change bits
            return keyboard.readMatrix(PRA) & PRB
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
    
    internal override func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case kDataPortRegisterAAddress:
            PRA = byte | ~DDRA
            vic.setMemoryBank(PRA & 0x3)
            // VIC + IEC stuff
        case kDataDirectionRegisterAAddress:
            //TODO: Should this update PRA immediately? Investigate
            DDRA = byte
        case kDataDirectionRegisterBAddress:
            DDRB = byte
        default:
            super.writeByte(position, byte: byte)
        }
    }
    
    internal override func readByte(position: UInt8) -> UInt8 {
        switch position {
        case kDataPortRegisterAAddress:
            //TODO: implement bit 7-8
            return (PRA | ~DDRA) & 0x3F
        default:
            return super.readByte(position)
        }
    }
}

