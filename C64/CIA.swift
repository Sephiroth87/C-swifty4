//
//  CIA.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 08/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

import Foundation

// Adapted from "A Software Model of the CIA6526" by Wolfgang Lorenz http://ist.uwaterloo.ca/~schepers/MJK/cia6526.html
private struct CIATimerState: BinaryConvertible {
    
    private struct CIATimerStateFlags {
        private static let Count0: UInt8 = 0x01
        private static let Count1: UInt8 = 0x02
        private static let Count2: UInt8 = 0x04
        private static let Count3: UInt8 = 0x08
        private static let Load0: UInt8 = 0x10
        private static let Load1: UInt8 = 0x20
        private static let Load2: UInt8 = 0x40
    }
    
    private var delay: UInt8 = 0
    private var feed: UInt8 = 0
    
    mutating func cycle() {
        delay = ((delay << 1) & ~(CIATimerStateFlags.Count0 | CIATimerStateFlags.Load0)) | feed
    }
    
    func shouldDecrement() -> Bool {
        return delay & CIATimerStateFlags.Count3 != 0
    }
    
    func shouldOutput() -> Bool {
        return delay & CIATimerStateFlags.Count2 != 0
    }
    
    mutating func start() {
        delay |= CIATimerStateFlags.Count1 | CIATimerStateFlags.Count0
        feed |= CIATimerStateFlags.Count0
    }
    
    mutating func stop() {
        delay &= ~(CIATimerStateFlags.Count1 | CIATimerStateFlags.Count0)
        feed &= ~CIATimerStateFlags.Count0
    }
    
    mutating func stopOneShot() {
        delay &= ~(CIATimerStateFlags.Count2 | CIATimerStateFlags.Count1 | CIATimerStateFlags.Count0)
        feed &= ~CIATimerStateFlags.Count0
    }
    
    mutating func setSkipNextClock() {
        delay &= ~CIATimerStateFlags.Count2
    }
    
    func shouldLoad() -> Bool {
        return delay & CIATimerStateFlags.Load1 != 0
    }
    
    mutating func setLoadNextCycle() {
        delay |= CIATimerStateFlags.Load0
    }
    
    mutating func setLoadThisCycle() {
        delay |= CIATimerStateFlags.Load1
    }
    
    //MARK: BinaryConvertible
    
    private func dump() -> [UInt8] {
        return [delay, feed]
    }
    
    private var binarySize: UInt {
        return 2
    }
    
    private static func extract(binaryDump: BinaryDump) -> CIATimerState {
        return CIATimerState(delay: binaryDump.next(), feed: binaryDump.next())
    }
    
}

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
    private var timerAState: CIATimerState = CIATimerState()
    private var timerBState: CIATimerState = CIATimerState()
    private var interruptDelay: Int8 = -1
    private var todLatched: Bool = false
    private var todRunning: Bool = false
    private var todCounter: UInt32 = 0
    private var pb6Toggle: Bool = false
    private var pb6Pulse: Bool = false
    private var pb7Toggle: Bool = false
    private var pb7Pulse: Bool = false
    //MARK: -
    
    //MARK: IECDevice lines for CIA2
    private var atnPin: Bool = true
    private var clkPin: Bool = true
    private var dataPin: Bool = true
    //MARK: -
    
    static func extract(binaryDump: BinaryDump) -> CIAState {
        return CIAState(pra: binaryDump.next(), prb: binaryDump.next(), ddra: binaryDump.next(), ddrb: binaryDump.next(), tod10ths: binaryDump.next(), todSec: binaryDump.next(), todMin: binaryDump.next(), todHr: binaryDump.next(), imr: binaryDump.next(), icr: binaryDump.next(), cra: binaryDump.next(), crb: binaryDump.next(), latchA: binaryDump.next(), counterA: binaryDump.next(), latchB: binaryDump.next(), counterB: binaryDump.next(), alarm10ths: binaryDump.next(), latch10ths: binaryDump.next(), alarmSec: binaryDump.next(), latchSec: binaryDump.next(), alarmMin: binaryDump.next(), latchMin: binaryDump.next(), alarmHr: binaryDump.next(), latchHr: binaryDump.next(), interruptPin: binaryDump.next(), timerAState: binaryDump.next(), timerBState: binaryDump.next(), interruptDelay: binaryDump.next(), todLatched: binaryDump.next(), todRunning: binaryDump.next(), todCounter: binaryDump.next(), pb6Toggle: binaryDump.next(), pb6Pulse: binaryDump.next(), pb7Toggle: binaryDump.next(), pb7Pulse: binaryDump.next(), atnPin: binaryDump.next(), clkPin: binaryDump.next(), dataPin: binaryDump.next())
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
        if state.pb6Pulse {
            state.pb6Pulse = false
        }
        if state.timerAState.shouldDecrement() {
            state.counterA = state.counterA &- 1
        }
        if state.counterA == 0 && state.timerAState.shouldOutput() {
            if state.cra & 0x08 != 0 {
                state.cra &= ~0x01
                state.timerAState.stopOneShot()
            }
            state.icr |= 0x01
            if state.imr & 0x01 != 0 {
                state.interruptDelay = 1
            }
            state.pb6Toggle = !state.pb6Toggle
            state.pb6Pulse = true
            state.timerAState.setLoadThisCycle()
        }
        if state.timerAState.shouldLoad() {
            state.counterA = state.latchA
            state.timerAState.setSkipNextClock()
        }
        state.timerAState.cycle()
        if state.pb7Pulse {
            state.pb7Pulse = false
        }
        if state.timerBState.shouldDecrement() {
            state.counterB = state.counterB &- 1
        }
        if state.counterB == 0 && state.timerBState.shouldOutput() {
            if state.crb & 0x08 != 0 {
                state.crb &= ~0x01
                state.timerBState.stopOneShot()
            }
            state.icr |= 0x02
            if state.imr & 0x02 != 0 {
                state.interruptDelay = 1
            }
            state.pb7Toggle = !state.pb7Toggle
            state.pb7Pulse = true
            state.timerBState.setLoadThisCycle()
        }
        if state.timerBState.shouldLoad() {
            state.counterB = state.latchB
            state.timerBState.setSkipNextClock()
        }
        state.timerBState.cycle()
        if state.interruptDelay == 0 {
            state.icr |= 0x80
            state.interruptDelay = -1
            triggerInterrupt()
        }
        if state.interruptDelay > 0 {
            state.interruptDelay -= 1
        }
        state.todCounter += 1
        let hzFactor = UInt32(state.cra & 0x80 == 0 ? 6 : 5)
        if state.todCounter == 65 * 263 * hzFactor { //TODO: use refresh rate of the system, currently fixed at 60hz NTSC
            state.todCounter = 0
            if state.todRunning {
                if state.tod10ths == 0x09 {
                    state.tod10ths = 0
                    if state.todSec == 0x59 {
                        state.todSec = 0
                        if state.todMin == 0x59 {
                            state.todMin = 0
                            let pm = (state.todHr & 0x80 != 0)
                            let hour = state.todHr & 0x1F
                            if hour == 0x12 {
                                state.todHr = 0x01
                            } else if hour < 0x12 {
                                state.todHr = incrementBCD(hour)
                            } else {
                                state.todHr = (hour & 0xF0) | ((hour & 0x0F) &+ 1)
                            }
                            if pm != (state.todHr == 0x12) {
                                state.todHr |= 0x80
                            }
                        } else {
                            state.todMin = incrementBCD(state.todMin) & 0x7F
                        }
                    } else {
                        state.todSec = incrementBCD(state.todSec) & 0x7F
                    }
                } else {
                    state.tod10ths = incrementBCD(state.tod10ths)
                }
                checkAlarm()
            }
        }
    }
    
    internal func writeByte(position: UInt8, byte: UInt8) {
        switch position {
        case 0x01:
            state.prb = byte | ~state.ddrb
        case 0x02:
            state.ddra = byte
        case 0x03:
            state.ddrb = byte
        case 0x04:
            state.latchA = (state.latchA & 0xFF00) | UInt16(byte)
        case 0x05:
            state.latchA = (UInt16(byte) << 8) | (state.latchA & 0xFF);
            if state.cra & 0x01 == 0 {
                state.timerAState.setLoadNextCycle()
            }
        case 0x06:
            state.latchB = (state.latchB & 0xFF00) | UInt16(byte)
        case 0x07:
            state.latchB = (UInt16(byte) << 8) | (state.latchB & 0xFF);
            if state.crb & 0x01 == 0 {
                state.timerBState.setLoadNextCycle()
            }
        case 0x08:
            let value = byte & 0x0F
            let changed: Bool
            if state.crb & 0x80 == 0 {
                if !state.todRunning {
                    state.todCounter = 0
                }
                state.todRunning = true
                changed = state.tod10ths != value
                state.tod10ths = byte & value
            } else {
                changed = state.alarm10ths != value
                state.alarm10ths = byte & value
            }
            if changed {
                checkAlarm()
            }
        case 0x09:
            let value = byte & 0x7F
            let changed: Bool
            if state.crb & 0x80 == 0 {
                changed = state.todSec != value
                state.todSec = value
            } else {
                changed = state.alarmSec != value
                state.alarmSec = value
            }
            if changed {
                checkAlarm()
            }
        case 0x0A:
            let value = byte & 0x7F
            let changed: Bool
            if state.crb & 0x80 == 0 {
                changed = state.todMin != value
                state.todMin = value
            } else {
                changed = state.alarmMin != value
                state.alarmMin = value
            }
            if changed {
                checkAlarm()
            }
        case 0x0B:
            let changed: Bool
            if state.crb & 0x80 == 0 {
                state.todRunning = false
                let value = (byte & 0x1F == 0x12 ? 0x12 | (~byte & 0x80) : byte & 0x9F)
                changed = state.todHr != value
                state.todHr = value
            } else {
                changed = state.alarmHr != byte & 0x9F
                state.alarmHr = byte & 0x9F
            }
            if changed {
                checkAlarm()
            }
        case 0x0C:
            //TODO: serial i/o
            return
        case 0x0D:
            if byte & 0x80 != 0 {
                state.imr |= (byte & 0x1F)
            } else {
                state.imr &= ~(byte & 0x1F)
            }
            if state.imr & state.icr != 0 {
                state.interruptDelay = 1
            }
        case 0x0E:
            // bit4: force load
            if byte & 0x10 != 0 {
                state.timerAState.setLoadNextCycle()
            }
            if byte & 0x01 != 0 {
                state.timerAState.start()
                if state.cra & 0x01 == 0 {
                    state.pb6Toggle = true
                }
            } else {
               state.timerAState.stop()
            }
            state.cra = byte
        case 0x0F:
            // bit4: force load
            if byte & 0x10 != 0 {
                state.timerBState.setLoadNextCycle()
            }
            if byte & 0x01 != 0 {
                state.timerBState.start()
                if state.crb & 0x01 == 0 {
                    state.pb7Toggle = true
                }
            } else {
                state.timerBState.stop()
            }
            state.crb = byte
        default:
            break
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
    
    private func checkAlarm() {
        if state.todHr == state.alarmHr && state.todMin == state.alarmMin && state.todSec == state.alarmSec && state.tod10ths == state.alarm10ths {
            state.icr |= 0x04
            if state.imr & 0x04 != 0 {
                state.icr |= 0x80
                triggerInterrupt()
            }
        }
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
            var result = keyboard.readMatrix(state.pra) & (state.prb | ~state.ddrb)
            if state.cra & 0x02 != 0 {
                if (state.cra & 0x04 == 0 && state.pb6Pulse) || (state.cra & 0x04 != 0 && state.pb6Toggle) {
                    result |= 0x40
                } else {
                    result &= ~0x40
                }
            }
            if state.crb & 0x02 != 0 {
                if (state.crb & 0x04 == 0 && state.pb7Pulse) || (state.crb & 0x04 != 0 && state.pb7Toggle) {
                    result |= 0x80
                } else {
                    result &= ~0x80
                }
            }
            return result
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
        case 0x01:
            var result = state.prb | ~state.ddrb
            if state.cra & 0x02 != 0 {
                if (state.cra & 0x04 == 0 && state.pb6Pulse) || (state.cra & 0x04 != 0 && state.pb6Toggle) {
                    result |= 0x40
                } else {
                    result &= ~0x40
                }
            }
            if state.crb & 0x02 != 0 {
                if (state.crb & 0x04 == 0 && state.pb7Pulse) || (state.crb & 0x04 != 0 && state.pb7Toggle) {
                    result |= 0x80
                } else {
                    result &= ~0x80
                }
            }
            return result
        default:
            return super.readByte(position)
        }
    }
    
    func iecUpdatedLines(atnLineUpdated atnLineUpdated: Bool, clkLineUpdated: Bool, dataLineUpdated: Bool) { }
    
}
