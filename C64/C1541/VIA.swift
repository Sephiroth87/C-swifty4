//
//  VIA.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 24/04/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

internal class VIA {
    
    internal weak var c1541: C1541!
    internal weak var cpu: CPU!
    
    //MARK: Registers
    private var orb: UInt8 = 0 // Output Register B
    private var irb: UInt8 = 0 // Input Register B
    private var ora: UInt8 = 0 // Output Register A
    private var ira: UInt8 = 0 // Input Register A
    private var ddrb: UInt8 = 0 // Data Direction Register B
    private var ddra: UInt8 = 0 // Data Direction Register A
    private var t1c: UInt16 = 0 // Timer 1 Counter
    private var t1ll: UInt8 = 0 // Timer 1 Low-Order Latch
    private var t1lh: UInt8 = 0 // Timer 1 High-Order Latch
    private var t2c: UInt16 = 0 // Timer 2 Counter
    private var t2ll: UInt8 = 0 // Timer 2 Low-Order Latch
    private var acr: UInt8 = 0 // Auxiliary Control Register
    private var pcr: UInt8 = 0 // Peripheral Control Register
    private var ifr: UInt8 = 0 // Interrupt Flag Register
    private var ier: UInt8 = 0 // Interrupt Enable Register
    //MARK: -
    
    //MARK: Helpers
    private var timer1Fired = true // We default to true so we don't fire until the counter is loaded from the latch
    private var timer2Fired = true
    //MARK: -
    
    internal func cycle() {
        //TODO: timing is not accurate, but it should be enough for now
        t1c = t1c &- 1
        if t1c == 0 && !timer1Fired {
            // Other emulators always reload timer 1 counter from latch, but the datasheet seems to imply that happens only in free-run mode, investigate later
            if acr & 0x40 != 0 {
                t1c = UInt16(t1lh) << 8 | UInt16(t1ll)
            } else {
                timer1Fired = true
            }
            ifr |= 0x40
            //TODO: handle PB7
            if ier & 0x40 != 0 {
                //TODO: better IRQ handling
                cpu.setIRQLine()
            }
        }
        if acr & 0x10 == 0 {
            t2c = t2c &- 1
        } else {
            //TODO: pulse counting mode
        }
        if t2c == 0 && !timer2Fired {
            timer2Fired = true
            ifr |= 0x20
            //TODO: handle PB7
            if ier & 0x20 != 0 {
                //TODO: better IRQ handling
                cpu.setIRQLine()
            }
        }
    }
    
    internal func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case 0x00:
            orb = byte
            //TODO: update pins logic
        case 0x01:
            ora = byte
            //TODO: update pins logic
        case 0x02:
            ddrb = byte
            // Update pins that were input and became output, crude way
            self.writeByte(0x00, byte: orb)
        case 0x03:
            ddra = byte
            //TODO: update pins logic
        case 0x04:
            t1ll = byte
        case 0x05:
            t1lh = byte
            t1c = UInt16(t1lh) << 8 | UInt16(t1ll)
            ifr &= ~0x40
            timer1Fired = false
        case 0x06:
            t1ll = byte
        case 0x07:
            // No mention of flag being cleared here in the datasheet, but other emulators do it...
            t1lh = byte
        case 0x08:
            t2ll = byte
        case 0x09:
            t2c = UInt16(byte) << 8 | UInt16(t2ll)
            ifr &= ~0x20
            timer2Fired = false
        case 0x0B:
            acr = byte
        case 0x0C:
            //TODO: do something with this?
            pcr = byte
        case 0x0D:
            ifr &= ~(byte & 0x7F)
        case 0x0E:
            if ((byte & 0x80) != 0) {
                ier |= (byte & 0x7F)
            } else {
                ier &= ~(byte & 0x7F)
            }
        default:
            println("todo via write address: " + String(position, radix: 16, uppercase: true))
            break
        }
    }
    
    internal func readByte(position: UInt8) -> UInt8 {
        switch position {
        case 0x00:
            //TODO: handle pin levels and latching
            return ddrb & orb
        case 0x04:
            ifr &= ~0x40
            return UInt8(truncatingBitPattern: t1c)
        case 0x05:
            return UInt8(truncatingBitPattern: t1c >> 8)
        case 0x06:
            return t1ll
        case 0x07:
            return t1lh
        case 0x08:
            ifr &= ~0x20
            return UInt8(truncatingBitPattern: t2c)
        case 0x09:
            return UInt8(truncatingBitPattern: t2c >> 8)
        case 0x0B:
            return acr
        case 0x0C:
            return pcr
        case 0x0D:
            return ifr | UInt8(ifr & ier != 0 ? 0x80 : 0)
        case 0x0E:
            return ier | 0x80
        default:
            println("todo via read address: " + String(position, radix: 16, uppercase: true))
            return 0
        }
    }
    
}

final internal class VIA1: VIA {
    
}

final internal class VIA2: VIA {
    
    override func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case 0x00:
            // Only set pins if data direction is 1 (output)
            // Should it update only if level has changed?
            if ddrb & 0x08 != 0 {
                c1541.updateLedStatus(byte & 0x08 != 0)
            }
            orb = byte
        default:
            super.writeByte(position, byte: byte)
        }
    }
    
}
