//
//  VIA.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 24/04/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

internal class VIA: LineComponent {
    
    internal weak var c1541: C1541!
    internal weak var interruptLine: Line!
    
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
    
    //MARK: Lines
    internal var ca1: Bool = false {
        didSet {
            if ca1 != oldValue {
                if (pcr & 0x01 == 0x00 && ca1 == false) || (pcr & 0x01 == 0x01 && ca1 == true) {
                    latchPA()
                    ifr |= 0x02
                    updateInterruptPin()
                }
            }
        }
    }
    internal var ca2: Bool = false
    internal var cb2: Bool = false
    //MARK: -
    
    //MARK: Helpers
    private var timer1Fired = true // We default to true so we don't fire until the counter is loaded from the latch
    private var timer2Fired = true
    private var interruptPin: Bool = true
    //MARK: -
    
    //MARK: LineComponent
    func pin(line: Line) -> Bool {
        return interruptPin
    }
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
            updateInterruptPin()
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
            updateInterruptPin()
        }
    }
    
    internal func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case 0x01:
            ora = byte
            // CA2 has some different clearing rules, but it's not used for now
            ifr &= ~0x03
            updateInterruptPin()
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
            updateInterruptPin()
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
            updateInterruptPin()
        case 0x0B:
            acr = byte
        case 0x0C:
            pcr = byte
            if pcr & 0x0E == 0x0E {
                ca2 = true
            } else if pcr & 0x0E == 0x0C {
                ca2 = false
            } else {
                // Unsupported CA2 operation mode
            }
            if pcr & 0xE0 == 0xE0 {
                cb2 = true
            } else if pcr & 0xE0 == 0xC0 {
                cb2 = false
            } else {
                // Unsupported CB2 operation mode
            }
        case 0x0D:
            ifr &= ~(byte & 0x7F)
            updateInterruptPin()
        case 0x0E:
            if ((byte & 0x80) != 0) {
                ier |= (byte & 0x7F)
            } else {
                ier &= ~(byte & 0x7F)
            }
            updateInterruptPin()
        default:
            print("todo via write address: " + String(position, radix: 16, uppercase: true))
            break
        }
    }
    
    internal func readByte(position: UInt8) -> UInt8 {
        switch position {
        case 0x04:
            ifr &= ~0x40
            updateInterruptPin()
            return UInt8(truncatingBitPattern: t1c)
        case 0x05:
            return UInt8(truncatingBitPattern: t1c >> 8)
        case 0x06:
            return t1ll
        case 0x07:
            return t1lh
        case 0x08:
            ifr &= ~0x20
            updateInterruptPin()
            return UInt8(truncatingBitPattern: t2c)
        case 0x09:
            return UInt8(truncatingBitPattern: t2c >> 8)
        case 0x0B:
            return acr
        case 0x0C:
            return pcr
        case 0x0D:
            return ifr | UInt8(ifr & ier != 0x00 ? 0x80 : 0x00)
        case 0x0E:
            return ier | 0x80
        default:
            print("todo via read address: " + String(position, radix: 16, uppercase: true))
            return 0
        }
    }
    
    func latchPA() { }
    
    private func updateInterruptPin() {
        interruptPin = (ifr & ier == 0x00)
        interruptLine.update(self)
    }
    
}

final internal class VIA1: VIA, IECDevice {
    
    internal weak var iec: IEC!
    
    //MARK: IECDevice
    internal var atnPin: Bool? {
        get {
            return nil
        }
    }
    internal var clkPin = true
    internal var dataPin = true
    //MARK: -
    
    //MARK: Helpers
    private var atnaPin = false
    //MARK: -
    
    override func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case 0x00:
            // Only set pins if data direction is 1 (output)
            // Should it update only if level has changed?
            clkPin = ddrb & 0x08 != 0 ? byte & 0x08 == 0 : clkPin
            dataPin = ddrb & 0x02 != 0 ? byte & 0x02 == 0 : dataPin
            atnaPin = ddrb & 0x10 != 0 ? byte & 0x10 != 0 : atnaPin
            updatePins()
            orb = byte
        default:
            super.writeByte(position, byte: byte)
        }
    }
    
    override func readByte(position: UInt8) -> UInt8 {
        switch position {
        case 0x00:
            // Latching?
            return (ddrb & orb) | (~ddrb & ((iec.clkLine ? 0x00 : 0x04) | (iec.dataLine ? 0x00 : 0x01) | (iec.atnLine ? 0x00: 0x80))) & 0x9F
        case 0x01:
            // CA2 has some different clearing rules, but it's not used for now
            ifr &= ~0x03
            updateInterruptPin()
            // PA is not connected on VIA1 so let's not do anything
            return 0xFF
        default:
            return super.readByte(position)
        }
    }
    
    func updatePins() {
        let oldDataPin = dataPin
        if (iec.dataLine || dataPin) && !iec.atnLine && !atnaPin {
            // Auto acknowledge
            dataPin = false
        }
        iec.updatePins(self)
        // We just want to pull down the line, but keep the actual pin level
        dataPin = oldDataPin
    }
    
    func iecUpdatedLines(atnLineUpdated atnLineUpdated: Bool, clkLineUpdated: Bool, dataLineUpdated: Bool) {
        updatePins()
        if atnLineUpdated {
            // CA1 interrupt, ATN is inverted so a positive edge will be seen here as negative
            if iec.atnLine == (pcr & 0x01 == 0) {
                ifr |= 0x02
                updateInterruptPin()
            }
        }
    }
    
}

final internal class VIA2: VIA {
    
    internal var pb7: Bool = false

    override func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case 0x00:
            // Only set pins if data direction is 1 (output)
            // Should it update only if level has changed?
            if ddrb & 0x04 != 0 {
                c1541.rotating = byte & 0x04 != 0
            }
            if ddrb & 0x08 != 0 {
                c1541.updateLedStatus(byte & 0x08 != 0)
            }
            c1541.setSpeedZone(Int((((orb & ~ddrb) | (byte & ddrb)) & 0x60) >> 5))
            let newStp = (byte & 0x03) & ddrb
            if newStp == (orb &+ 1) & 0x03 { // This should actually be read from pin level, since it's not always orb, but maybe it doesn't matter
                c1541.moveHeadUp()
            } else if newStp == (orb &- 1) & 0x03 {
                c1541.moveHeadDown()
            }
            orb = byte
        default:
            super.writeByte(position, byte: byte)
        }
    }
    
    override func readByte(position: UInt8) -> UInt8 {
        switch position {
        case 0x00:
            //TODO: Implement actual pins
            //TODO: Latching?
            return (ddrb & orb) | (~ddrb & ((c1541.rotating ? 0x04 : 0x00) | (pb7 ? 0x00 : 0x80) | (/* Write protect pin*/ false ? 0x00 : 0x10)))
        case 0x01, 0x0F:
            // CA2 has some different clearing rules, but it's not used for now
            ifr &= ~0x03
            updateInterruptPin()
            if acr & 0x01 == 0x00 {
                // Latching disabled, return PA pins
                return c1541.shiftRegister
            } else {
                // Latching enabled, return IRA
                return ira
            }
        default:
            return super.readByte(position)
        }
    }
    
    override func latchPA() {
        ira = c1541.shiftRegister
    }
    
}
