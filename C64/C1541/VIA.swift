//
//  VIA.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 24/04/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

internal class VIA {
    
    internal weak var c1541: C1541!
    
    //MARK: Registers
    private var orb: UInt8 = 0 // Output Register B
    private var irb: UInt8 = 0 // Input Register B
    private var ora: UInt8 = 0 // Output Register A
    private var ira: UInt8 = 0 // Input Register A
    private var ddrb: UInt8 = 0 // Data Direction Register B
    private var ddra: UInt8 = 0 // Data Direction Register A
    private var t1cl: UInt8 = 0 // Timer 1 Low-Order Counter
    private var t1ch: UInt8 = 0 // Timer 1 High-Order Counter
    private var t1ll: UInt8 = 0 // Timer 1 Low-Order Latch
    private var t1lh: UInt8 = 0 // Timer 1 High-Order Latch
    private var t2cl: UInt8 = 0 // Timer 2 Low-Order Counter
    private var t2ch: UInt8 = 0 // Timer 2 High-Order Counter
    private var t2ll: UInt8 = 0 // Timer 2 Low-Order Latch
    private var acr: UInt8 = 0 // Auxiliary Control Register
    private var pcr: UInt8 = 0 // Peripheral Control Register
    private var ifr: UInt8 = 0 // Interrupt Flag Register
    private var ier: UInt8 = 0 // Interrupt Enable Register
    //MARK: -
    
    internal func cycle() {
        
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
            t1cl = t1ll
            t1ch = t1lh
            ifr &= ~0x40
        case 0x06:
            t1ll = byte
        case 0x07:
            t1lh = byte
        case 0x08:
            t2ll = byte
        case 0x09:
            t2ch = byte
            t2cl = t2ll
            ifr &= ~0x20
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
            return t1cl
        case 0x05:
            return t1ch
        case 0x06:
            return t1ll
        case 0x07:
            return t1lh
        case 0x08:
            ifr &= ~0x20
            return t2cl
        case 0x09:
            return t2ch
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
