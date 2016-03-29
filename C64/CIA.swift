//
//  CIA.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 08/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

import Foundation

internal struct CIAState: ComponentState {
    
    //MARK: Registers
    private var pra: UInt8 = 0xFF // Data Port Register A
    private var prb: UInt8 = 0xFF // Data Port Register B
    private var ddra: UInt8 = 0 // Data Direction Register A
    private var ddrb: UInt8 = 0 // Data Direction Register B
    private var tod10ths: UInt8 = 0 // 10ths of seconds register
    private var todSec: UInt8 = 0 // Seconds register
    private var todMin: UInt8 = 0 // Minutes register
    private var todHr: UInt8 = 1 // Hours — AM/PM register
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
    private var alarm10ths: UInt8 = 0
    private var latch10ths: UInt8 = 0
    private var alarmSec: UInt8 = 0
    private var latchSec: UInt8 = 0
    private var alarmMin: UInt8 = 0
    private var latchMin: UInt8 = 0
    private var alarmHr: UInt8 = 0
    private var latchHr: UInt8 = 0
    //MARK: -
    
    //MARK: Helpers
    private var interruptPin: Bool = true
    private var timerADelay: UInt8 = 0
    private var timerBDelay: UInt8 = 0
    private var interruptDelay: Int8 = -1
    private var todLatched: Bool = false
    private var todRunning: Bool = true
    private var todCounter: UInt16 = 0
    //MARK: -
    
    //MARK: IECDevice lines for CIA2
    private var atnPin: Bool = true
    private var clkPin: Bool = true
    private var dataPin: Bool = true
    //MARK: -
    
    mutating func update(dictionary: [String: AnyObject]) {
        pra = UInt8(dictionary["pra"] as! UInt)
        prb = UInt8(dictionary["prb"] as! UInt)
        ddra = UInt8(dictionary["ddra"] as! UInt)
        ddrb = UInt8(dictionary["ddrb"] as! UInt)
        tod10ths = UInt8(dictionary["tod10ths"] as! UInt)
        todSec = UInt8(dictionary["todSec"] as! UInt)
        todMin = UInt8(dictionary["todMin"] as! UInt)
        todHr = UInt8(dictionary["todHr"] as! UInt)
        imr = UInt8(dictionary["imr"] as! UInt)
        icr = UInt8(dictionary["icr"] as! UInt)
        cra = UInt8(dictionary["cra"] as! UInt)
        crb = UInt8(dictionary["crb"] as! UInt)
        latchA = UInt16(dictionary["latchA"] as! UInt)
        counterA = UInt16(dictionary["counterA"] as! UInt)
        latchB = UInt16(dictionary["latchB"] as! UInt)
        counterB = UInt16(dictionary["counterB"] as! UInt)
        alarm10ths = UInt8(dictionary["alarm10ths"] as! UInt)
        latch10ths = UInt8(dictionary["latch10ths"] as! UInt)
        alarmSec = UInt8(dictionary["alarmSec"] as! UInt)
        latchSec = UInt8(dictionary["latchSec"] as! UInt)
        alarmMin = UInt8(dictionary["alarmMin"] as! UInt)
        latchMin = UInt8(dictionary["latchMin"] as! UInt)
        alarmHr = UInt8(dictionary["alarmHr"] as! UInt)
        latchHr = UInt8(dictionary["latchHr"] as! UInt)
        interruptPin = dictionary["interruptPin"] as! Bool
        timerADelay = UInt8(dictionary["timerADelay"] as! UInt)
        timerBDelay = UInt8(dictionary["timerBDelay"] as! UInt)
        interruptDelay = Int8(dictionary["timerBDelay"] as! Int)
        todLatched = dictionary["todLatched"] as! Bool
        todRunning = dictionary["todRunning"] as! Bool
        todCounter = UInt16(dictionary["todCounter"] as! UInt)
        atnPin = dictionary["atnPin"] as! Bool
        clkPin = dictionary["clkPin"] as! Bool
        dataPin = dictionary["dataPin"] as! Bool
    }
    
}

internal class CIA: Component, LineComponent {
    
    internal var state = CIAState()

    internal weak var interruptLine: Line!
    internal var crashHandler: C64CrashHandler?
    
    //MARK: LineComponent
    func pin(line: Line) -> Bool {
        return state.interruptPin
    }
    //MARK: -
   
    internal func cycle() {
        if state.cra & 0x01 != 0 && state.timerADelay == 0 {
            if state.cra & 0x20 == 0x00 {
                // o2 mode
                state.counterA = state.counterA &- 1
                if state.counterA == 0 || state.counterA == 0xFFFF {
                    state.counterA = state.latchA
                    if state.cra & 0x08 != 0 {
                        state.cra &= ~0x01
                    } else {
                        state.timerADelay = 1
                    }
                    state.icr |= 0x01
                    if state.imr & 0x01 != 0 {
                        state.interruptDelay = 1
                    }
                }
            } else {
                //TODO: CNT mode
            }
        }
        if state.timerADelay > 0 {
            --state.timerADelay
        }
        if state.crb & 0x01 != 0 && state.timerBDelay == 0 {
            if state.crb & 0x20 == 0x00 {
                // o2 mode
                state.counterB = state.counterB &- 1
                if state.counterB == 0 || state.counterB == 0xFFFF {
                    state.counterB = state.latchB
                    if state.crb & 0x08 != 0 {
                        state.crb &= ~0x01
                    } else {
                        state.timerBDelay = 1
                    }
                    state.icr |= 0x02
                    if state.imr & 0x02 != 0 {
                        state.interruptDelay = 1
                    }
                }
            } else {
                //TODO: CNT mode
            }
        }
        if state.timerBDelay > 0 {
            --state.timerBDelay
        }
        if state.interruptDelay == 0 {
            state.icr |= 0x80
            state.interruptDelay = -1
            triggerInterrupt()
        }
        if state.interruptDelay > 0 {
            --state.interruptDelay
        }
        state.todCounter += 1
        if state.todCounter == 65 * 263 { //TODO: actually use 50/60 hz flag
            state.todCounter = 0
            if state.todRunning {
                if state.tod10ths == 0x09 {
                    state.tod10ths = 0
                    if state.todSec == 0x59 {
                        state.todSec = 0
                        if state.todMin == 0x59 {
                            state.todMin = 0
                            let pm = (state.todHr & 0x80 != 0)
                            if state.todHr & 0x1F == 0x12 {
                                state.todHr = 0x01
                            } else {
                                state.todHr = incrementBCD(state.todHr & 0x1F)
                                if state.todHr == 0x12 && !pm {
                                    state.todHr |= 0x80
                                }
                            }
                        } else {
                            state.todMin = incrementBCD(state.todMin)
                        }
                    } else {
                        state.todSec = incrementBCD(state.todSec)
                    }
                } else {
                    state.tod10ths = incrementBCD(state.tod10ths)
                }
            }
        }
        if state.todHr == state.alarmHr && state.todMin == state.alarmMin && state.todSec == state.alarmSec && state.tod10ths == state.alarm10ths {
            state.icr |= 0x04
            if state.imr & 0x04 != 0 {
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
        case 0x08:
            if state.crb & 0x80 == 0 {
                state.todRunning = true
                state.tod10ths = byte & 0x0F
            } else {
                state.alarm10ths = byte & 0x0F
            }
        case 0x09:
            if state.crb & 0x80 == 0 {
                state.todSec = byte & 0x7F
            } else {
                state.alarmSec = byte & 0x7F
            }
        case 0x0A:
            if state.crb & 0x80 == 0 {
                state.todMin = byte & 0x7F
            } else {
                state.alarmMin = byte & 0x7F
            }
        case 0x0B:
            if state.crb & 0x80 == 0 {
                state.todRunning = false
                state.todHr = byte & 0x9F
            } else {
                state.alarmHr = byte & 0x9F
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
            if state.imr & state.icr != 0 {
                state.interruptDelay = 1
            }
        case 0x0E:
            // bit4: force load
            if ((byte & 0x10) != 0) {
                state.counterA = state.latchA
                state.timerADelay = 3
            }
            state.cra = byte
        case 0x0F:
            // bit4: force load
            if ((byte & 0x10) != 0) {
                state.counterB = state.latchB
                state.timerBDelay = 3
            }
            state.crb = byte
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
        case 0x08:
            let value = state.todLatched ? state.latch10ths : state.tod10ths
            state.todLatched = false
            return value
        case 0x09:
            return state.todLatched ? state.latchSec : state.todSec
        case 0x0A:
            return state.todLatched ? state.latchMin : state.todMin
        case 0x0B:
            if !state.todLatched {
                state.todLatched = true
                state.latch10ths = state.tod10ths
                state.latchSec = state.todSec
                state.latchMin = state.todMin
                state.latchHr = state.todHr
            }
            return state.latchHr
        case 0x0C:
            //TODO: serial i/o
            return 0
        case 0x0D:
            clearInterrupt()
            let value = state.icr
            state.icr = 0
            state.interruptDelay = -1
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
    
    private func triggerInterrupt() {
        state.interruptPin = false
        interruptLine.update(self)
    }
    
    private func clearInterrupt() {
        state.interruptPin = true
        interruptLine.update(self)
    }
    
    private func incrementBCD(value: UInt8) -> UInt8 {
        return ((value & 0x0F) == 0x09) ? (value & 0xF0) + 0x10 : (value & 0xF0) + ((value + 0x01) & 0x0F)
    }
    
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
