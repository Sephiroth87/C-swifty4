//
//  CPU+Opcodes.swift
//  C64
//
//  Created by Fabio on 19/12/2016.
//  Copyright © 2016 orange in a day. All rights reserved.
//

extension CPU {
    
    //MARK: ADC
    
    internal func adc(_ value: UInt8) {
        if state.d {
            var lowNybble = (state.a & 0x0F) &+ (value & 0x0F) &+ (state.c ? 1 : 0)
            var highNybble = (state.a >> 4) &+ (value >> 4)
            if lowNybble > 9 {
                lowNybble = lowNybble &+ 6
            }
            if lowNybble > 0x0F {
                highNybble = highNybble &+ 1
            }
            state.z = ((state.a &+ value &+ (state.c ? 1 : 0)) & 0xFF == 0)
            state.n = (highNybble & 0x08 != 0)
            state.v = ((((highNybble << 4) ^ state.a) & 0x80) != 0 && ((state.a ^ value) & 0x80) == 0)
            if highNybble > 9 {
                highNybble = highNybble &+ 6
            }
            state.c = (highNybble > 0x0F)
            state.a = (highNybble << 4) | (lowNybble & 0x0F)
        } else {
            let tempA = UInt16(state.a)
            let sum = (tempA + UInt16(value) + (state.c ? 1 : 0))
            state.c = (sum > 0xFF)
            state.v = (((tempA ^ UInt16(value)) & 0x80) == 0 && ((tempA ^ sum) & 0x80) != 0)
            loadA(UInt8(truncatingBitPattern: sum))
        }
    }
    
    internal func adcImmediate() {
        if loadDataImmediate() {
            adc(state.data)
            state.cycle = 0
        }
    }
    
    internal func adcZeroPage() {
        if loadDataZeroPage() {
            adc(state.data)
            state.cycle = 0
        }
    }
    
    internal func adcPageBoundary() {
        if loadDataAbsolute() {
            if state.pageBoundaryCrossed {
                state.addressHigh = state.addressHigh &+ 1
            } else {
                adc(state.data)
                state.cycle = 0
            }
        }
    }
    
    internal func adcAbsolute() {
        if loadDataAbsolute() {
            adc(state.data)
            state.cycle = 0
        }
    }
    
    //MARK: ALR*
    
    internal func alrImmediate() {
        if loadDataImmediate() {
            let a = state.a & state.data
            state.c = ((a & 1) != 0)
            loadA(a >> 1)
            state.cycle = 0
        }
    }
    
    //MARK: ANC*
    
    internal func ancImmediate() {
        if loadDataImmediate() {
            loadA(state.a & state.data)
            state.c = state.n
            state.cycle = 0
        }
    }
    
    //MARK: AND
    
    internal func andImmediate() {
        if loadDataImmediate() {
            loadA(state.a & state.data)
            state.cycle = 0
        }
    }
    
    internal func andZeroPage() {
        if loadDataZeroPage() {
            loadA(state.a & state.data)
            state.cycle = 0
        }
    }
    
    internal func andPageBoundary() {
        if loadDataAbsolute() {
            if state.pageBoundaryCrossed {
                state.addressHigh = state.addressHigh &+ 1
            } else {
                loadA(state.a & state.data)
                state.cycle = 0
            }
        }
    }
    
    internal func andAbsolute() {
        if loadDataAbsolute() {
            loadA(state.a & state.data)
            state.cycle = 0
        }
    }
    
    //MARK: ANE*
    
    internal func aneImmediate() {
        if loadDataImmediate() {
            //TODO: From http://www.zimmers.net/anonftp/pub/cbm/documents/chipdata/64doc, number might be different than 0xEE
            loadA((state.a | 0xEE) & state.x & state.data)
            state.cycle = 0
        }
    }
    
    //MARK: ARR*
    
    internal func arrImmediate() {
        if loadDataImmediate() {
            let tempA = state.a & state.data
            state.a = (tempA >> 1) + (state.c ? 0x80 : 0)
            if state.d {
                state.n = state.c
                state.z = (state.a == 0)
                state.v = (((tempA ^ state.a) & 0x40) != 0)
                
                if (tempA & 0x0F) + (tempA & 0x01) > 5 {
                    state.a = (state.a & 0xF0) | ((state.a &+ 6) & 0x0F)
                }
                if UInt16(tempA & 0xF0) &+ UInt16(tempA & 0x10) > 0x50 {
                    state.c = true
                    state.a = state.a &+ 0x60
                } else {
                    state.c = false
                }
            } else {
                state.z = (state.a == 0)
                state.n = (state.a & 0x80 != 0)
                state.c = ((state.a & 0x40) != 0)
                state.v = (((state.a & 0x40) ^ ((state.a & 0x20) << 1)) != 0)
            }
            state.cycle = 0
        }
    }
    
    //MARK: ASL
    
    internal func aslAccumulator() {
        if idleReadImplied() {
            state.c = ((state.a & 0x80) != 0)
            loadA(state.a << 1)
            state.cycle = 0
        }
    }
    
    internal func aslZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.c = ((state.data & 0x80) != 0)
        state.data = state.data << 1
    }
    
    internal func aslAbsolute() {
        memory.writeByte(address, byte: state.data)
        state.c = ((state.data & 0x80) != 0)
        state.data = state.data << 1
    }
    
    //MARK: BCC
    
    internal func branch() {
        if idleReadImplied() {
            let oldPch = pch
            state.pc = state.pc &+ Int8(bitPattern: state.data)
            if pch == oldPch {
                if state.irqDelayCounter >= 0 {
                    state.irqDelayCounter += 1
                }
                if state.nmiDelayCounter >= 0 {
                    state.nmiDelayCounter += 1
                }
                state.cycle = 0
            }
        }
    }
    
    internal func branchOverflow() {
        if rdyLine.state {
            if state.data & 0x80 != 0 {
                memory.readByte(state.pc &+ UInt16(0x100))
            } else {
                memory.readByte(state.pc &- UInt16(0x100))
            }
            state.cycle = 0
        } else {
            state.cycle -= 1
        }
    }
    
    internal func bccRelative() {
        if loadDataImmediate() {
            if state.c {
                state.cycle = 0
            }
        }
    }
    
    //MARK: BCS
    
    internal func bcsRelative() {
        if loadDataImmediate() {
            if !state.c {
                state.cycle = 0
            }
        }
    }
    
    //MARK: BEQ
    
    internal func beqRelative() {
        if loadDataImmediate() {
            if !state.z {
                state.cycle = 0
            }
        }
    }
    
    //MARK: BIT
    
    internal func bitZeroPage() {
        if loadDataZeroPage() {
            state.n = ((state.data & 128) != 0)
            state.v = ((state.data & 64) != 0)
            state.z = ((state.data & state.a) == 0)
            state.cycle = 0
        }
    }
    
    internal func bitAbsolute() {
        if loadDataAbsolute() {
            state.n = ((state.data & 128) != 0)
            state.v = ((state.data & 64) != 0)
            state.z = ((state.data & state.a) == 0)
            state.cycle = 0
        }
    }
    
    //MARK: BMI
    
    internal func bmiRelative() {
        if loadDataImmediate() {
            if !state.n {
                state.cycle = 0
            }
        }
    }
    
    //MARK: BNE
    
    internal func bneRelative() {
        if loadDataImmediate() {
            if state.z {
                state.cycle = 0
            }
        }
    }
    
    //MARK: BPL
    
    internal func bplRelative() {
        if loadDataImmediate() {
            if state.n {
                state.cycle = 0
            }
        }
    }
    
    //MARK: BRK
    
    internal func brkImplied() {
        state.b = true
        pushPch()
    }
    
    internal func brkImplied2() {
        pushPcl()
    }
    
    internal func brkImplied3() {
        let p = UInt8((state.c ? 0x01 : 0) |
            (state.z ? 0x02 : 0) |
            (state.i ? 0x04 : 0) |
            (state.d ? 0x08 : 0) |
            (state.b ? 0x10 : 0) |
            0x20 |
            (state.v ? 0x40 : 0) |
            (state.n ? 0x80 : 0))
        memory.writeByte(0x100 &+ state.sp, byte: p)
        state.sp = state.sp &- 1
    }
    
    internal func brkImplied4() {
        if state.nmiDelayCounter == 0 {
            state.data = memory.readByte(0xFFFA)
        } else {
            state.data = memory.readByte(0xFFFE)
            if state.nmiDelayCounter == 1 {
                state.nmiDelayCounter = 2
            }
        }
    }

    internal func brkImplied5() {
        pcl = state.data
        if state.nmiDelayCounter == 0 {
            pch = memory.readByte(0xFFFB)
            state.nmiDelayCounter = -1
        } else {
            pch = memory.readByte(0xFFFF)
            //TODO: there might be some delays here if NMI is not converted, but I'm not sure
        }
        state.i = true
        state.cycle = 0
    }

    //MARK: BVC

    internal func bvcRelative() {
        if loadDataImmediate() {
            if state.v {
                state.cycle = 0
            }
        }
    }
    
    //MARK: BVS
    
    internal func bvsRelative() {
        if loadDataImmediate() {
            if !state.v {
                state.cycle = 0
            }
        }
    }
    
    //MARK: CLC
    
    internal func clcImplied() {
        if idleReadImplied() {
            state.c = false
            state.cycle = 0
        }
    }
    
    //MARK: CLD
    
    internal func cldImplied() {
        if idleReadImplied() {
            state.d = false
            state.cycle = 0
        }
    }
    
    //MARK: CLI
    
    internal func cliImplied() {
        if idleReadImplied() {
            state.i = false
            state.cycle = 0
        }
    }
    
    //MARK: CLV
    
    internal func clvImplied() {
        if idleReadImplied() {
            state.v = false
            state.cycle = 0
        }
    }
    
    //MARK: CMP
    
    internal func cmp(_ value1: UInt8, _ value2: UInt8) {
        let diff = value1 &- value2
        state.z = (diff == 0)
        state.n = (diff & 0x80 != 0)
        state.c = (value1 >= value2)
    }
    
    internal func cmpImmediate() {
        if loadDataImmediate() {
            cmp(state.a, state.data)
            state.cycle = 0
        }
    }
    
    internal func cmpZeroPage() {
        if loadDataZeroPage() {
            cmp(state.a, state.data)
            state.cycle = 0
        }
    }
    
    internal func cmpAbsolute() {
        if loadDataAbsolute() {
            cmp(state.a, state.data)
            state.cycle = 0
        }
    }
    
    internal func cmpPageBoundary() {
        if loadDataAbsolute() {
            if state.pageBoundaryCrossed {
                state.addressHigh = state.addressHigh &+ 1
            } else {
                cmp(state.a, state.data)
                state.cycle = 0
            }
        }
    }
    
    //MARK: CPX
    
    internal func cpxImmediate() {
        if loadDataImmediate() {
            cmp(state.x, state.data)
            state.cycle = 0
        }
    }
    
    internal func cpxZeroPage() {
        if loadDataZeroPage() {
            cmp(state.x, state.data)
            state.cycle = 0
        }
    }
    
    internal func cpxAbsolute() {
        if loadDataAbsolute() {
            cmp(state.x, state.data)
            state.cycle = 0
        }
    }
    
    //MARK: CPY
    
    internal func cpyImmediate() {
        if loadDataImmediate() {
            cmp(state.y, state.data)
            state.cycle = 0
        }
    }
    
    internal func cpyZeroPage() {
        if loadDataZeroPage() {
            cmp(state.y, state.data)
            state.cycle = 0
        }
    }
    
    internal func cpyAbsolute() {
        if loadDataAbsolute() {
            cmp(state.y, state.data)
            state.cycle = 0
        }
    }
    
    //MARK: DCP*
    
    internal func dcpZeroPage() {
        decZeroPage()
    }
    
    internal func dcpZeroPage2() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        cmp(state.a, state.data)
        state.cycle = 0
    }
    
    internal func dcpAbsolute() {
        decAbsolute()
    }
    
    internal func dcpAbsolute2() {
        memory.writeByte(address, byte: state.data)
        cmp(state.a, state.data)
        state.cycle = 0
    }
    
    //MARK: DEC
    
    internal func decZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.data = state.data &- 1
    }
    
    internal func decAbsolute() {
        memory.writeByte(address, byte: state.data)
        state.data = state.data &- 1
    }
    
    //MARK: DEX
    
    internal func dexImplied() {
        loadX(state.x &- 1)
        state.cycle = 0
    }
    
    //MARK: DEY
    
    internal func deyImplied() {
        loadY(state.y &- 1)
        state.cycle = 0
    }
    
    //MARK: EOR
    
    internal func eorImmediate() {
        if loadDataImmediate() {
            loadA(state.a ^ state.data)
            state.cycle = 0
        }
    }
    
    internal func eorZeroPage() {
        if loadDataZeroPage() {
            loadA(state.a ^ state.data)
            state.cycle = 0
        }
    }
    
    internal func eorAbsolute() {
        if loadDataAbsolute() {
            loadA(state.a ^ state.data)
            state.cycle = 0
        }
    }
    
    internal func eorPageBoundary() {
        if loadDataAbsolute() {
            if state.pageBoundaryCrossed {
                state.addressHigh = state.addressHigh &+ 1
            } else {
                loadA(state.a ^ state.data)
                state.cycle = 0
            }
        }
    }
    
    //MARK: INC
    
    internal func incZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.data = state.data &+ 1
    }
    
    internal func incAbsolute() {
        memory.writeByte(address, byte: state.data)
        state.data = state.data &+ 1
    }
    
    //MARK: INX
    
    internal func inxImplied() {
        if idleReadImplied() {
            loadX(state.x &+ 1)
            state.cycle = 0
        }
    }
    
    //MARK: INY
    
    internal func inyImplied() {
        if idleReadImplied() {
            loadY(state.y &+ 1)
            state.cycle = 0
        }
    }
    
    //MARK: ISB*
    
    internal func isbZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.data = state.data &+ 1
    }
    
    internal func isbZeroPage2() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        zeroPageWriteUpdateNZ()
        sbc(state.data)
        state.cycle = 0
    }
    
    internal func isbAbsolute() {
        memory.writeByte(address, byte: state.data)
        state.data = state.data &+ 1
    }
    
    internal func isbAbsolute2() {
        memory.writeByte(address, byte: state.data)
        absoluteWriteUpdateNZ()
        sbc(state.data)
        state.cycle = 0
    }
    
    //MARK: JMP
    
    internal func jmpAbsolute() {
        if loadAddressHigh() {
            state.pc = address
            state.cycle = 0
        }
    }
    
    internal func jmpIndirect() {
        pcl = state.data
        state.addressLow = state.addressLow &+ 1
        pch = memory.readByte(address)
        state.cycle = 0
    }

    //MARK: JSR
    
    internal func jsrAbsolute() {
        if loadAddressHigh() {
            state.pc = address
            state.cycle = 0
        }
    }
    
    //MARK: LAS*
    
    internal func lasPageBoundary() {
        if loadDataAbsolute() {
            if state.pageBoundaryCrossed {
                state.addressHigh = state.addressHigh &+ 1
            } else {
                state.data &= state.sp
                state.sp = state.data
                state.x = state.data
                loadA(state.data)
                state.cycle = 0
            }
        }
    }
    
    internal func lasAbsolute() {
        if loadDataAbsolute() {
            state.data &= state.sp
            state.sp = state.data
            state.x = state.data
            loadA(state.data)
            state.cycle = 0
        }
    }
    
    //MARK: LAX*
    
    internal func laxZeroPage() {
        if loadDataZeroPage() {
            loadA(state.data)
            loadX(state.data)
            state.cycle = 0
        }
    }
    
    internal func laxPageBoundary() {
        if loadDataAbsolute() {
            if state.pageBoundaryCrossed {
                state.addressHigh = state.addressHigh &+ 1
            } else {
                loadA(state.data)
                loadX(state.data)
                state.cycle = 0
            }
        }
    }
    
    internal func laxAbsolute() {
        if loadDataAbsolute() {
            loadA(state.data)
            loadX(state.data)
            state.cycle = 0
        }
    }
    
    //MARK: LDA
    
    internal func ldaImmediate() {
        if loadDataImmediate() {
            loadA(state.data)
            state.cycle = 0
        }
    }
    
    internal func ldaZeroPage() {
        if loadDataZeroPage() {
            loadA(state.data)
            state.cycle = 0
        }
    }
    
    internal func ldaAbsolute() {
        if loadDataAbsolute() {
            loadA(state.data)
            state.cycle = 0
        }
    }
    
    internal func ldaPageBoundary() {
        if loadDataAbsolute() {
            if state.pageBoundaryCrossed {
                state.addressHigh = state.addressHigh &+ 1
            } else {
                loadA(state.data)
                state.cycle = 0
            }
        }
    }
    
    //MARK: LDX
    
    internal func ldxImmediate() {
        if loadDataImmediate() {
            loadX(state.data)
            state.cycle = 0
        }
    }
    
    internal func ldxZeroPage() {
        if loadDataZeroPage() {
            loadX(state.data)
            state.cycle = 0
        }
    }
    
    internal func ldxAbsolute() {
        if loadDataAbsolute() {
            loadX(state.data)
            state.cycle = 0
        }
    }
    
    internal func ldxPageBoundary() {
        if loadDataAbsolute() {
            if state.pageBoundaryCrossed {
                state.addressHigh = state.addressHigh &+ 1
            } else {
                loadX(state.data)
                state.cycle = 0
            }
        }
    }
    
    //MARK: LDY
    
    internal func ldyImmediate() {
        if loadDataImmediate() {
            loadY(state.data)
            state.cycle = 0
        }
    }
    
    internal func ldyZeroPage() {
        if loadDataZeroPage() {
            loadY(state.data)
            state.cycle = 0
        }
    }
    
    internal func ldyAbsolute() {
        if loadDataAbsolute() {
            loadY(state.data)
            state.cycle = 0
        }
    }
    
    internal func ldyPageBoundary() {
        if loadDataAbsolute() {
            if state.pageBoundaryCrossed {
                state.addressHigh = state.addressHigh &+ 1
            } else {
                loadY(state.data)
                state.cycle = 0
            }
        }
    }
    
    //MARK: LSR
    
    internal func lsrAccumulator() {
        if idleReadImplied() {
            state.c = ((state.a & 1) != 0)
            loadA(state.a >> 1)
            state.cycle = 0
        }
    }
    
    internal func lsrZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.c = ((state.data & 1) != 0)
        state.data = state.data >> 1
    }
    
    internal func lsrAbsolute() {
        memory.writeByte(address, byte: state.data)
        state.c = ((state.data & 1) != 0)
        state.data = state.data >> 1
    }
    
    //MARK: LXA*
    
    internal func lxaImmediate() {
        if loadDataImmediate() {
            //TODO: From http://www.zimmers.net/anonftp/pub/cbm/documents/chipdata/64doc, number might be different than 0xEE
            state.x = state.data & (state.a | 0xEE)
            loadA(state.x)
            state.cycle = 0
        }
    }
    
    //MARK: NOP
    
    internal func nop() {
        if idleReadImplied() {
            state.cycle = 0
        }
    }
    
    internal func nopZeroPage() {
        if loadDataZeroPage() {
            state.cycle = 0
        }
    }
    
    internal func nopImmediate() {
        if loadDataImmediate() {
            state.cycle = 0
        }
    }
    
    internal func nopPageBoundary() {
        if loadDataAbsolute() {
            if state.pageBoundaryCrossed {
                state.addressHigh = state.addressHigh &+ 1
            } else {
                state.cycle = 0
            }
        }
    }
    
    internal func nopAbsolute() {
        if loadDataAbsolute() {
            state.cycle = 0
        }
    }
    
    //MARK: ORA
    
    internal func oraImmediate() {
        if loadDataImmediate() {
            loadA(state.a | state.data)
            state.cycle = 0
        }
    }
    
    internal func oraZeroPage() {
        if loadDataZeroPage() {
            loadA(state.a | state.data)
            state.cycle = 0
        }
    }
    
    internal func oraPageBoundary() {
        if loadDataAbsolute() {
            if state.pageBoundaryCrossed {
                state.addressHigh = state.addressHigh &+ 1
            } else {
                loadA(state.a | state.data)
                state.cycle = 0
            }
        }
    }
    
    internal func oraAbsolute() {
        if loadDataAbsolute() {
            loadA(state.a | state.data)
            state.cycle = 0
        }
    }
    
    //MARK: PHA
    
    internal func phaImplied() {
        memory.writeByte(0x100 &+ state.sp, byte: state.a)
        state.sp = state.sp &- 1
        state.cycle = 0
    }
    
    //MARK: PHP
    
    internal func phpImplied() {
        let p = UInt8((state.c ? 0x01 : 0) |
            (state.z ? 0x02 : 0) |
            (state.i ? 0x04 : 0) |
            (state.d ? 0x08 : 0) |
            (state.b ? 0x10 : 0) |
            0x20 |
            (state.v ? 0x40 : 0) |
            (state.n ? 0x80 : 0))
        memory.writeByte(0x100 &+ state.sp, byte: p)
        state.sp = state.sp &- 1
        state.cycle = 0
    }
    
    //MARK: PLA
    
    internal func plaImplied() {
        if rdyLine.state {
            loadA(memory.readByte(0x100 &+ state.sp))
            state.cycle = 0
        } else {
            state.cycle -= 1
        }
    }

    //MARK: PLP

    internal func plpImplied() {
        if rdyLine.state {
            let p =  memory.readByte(0x100 &+ state.sp)
            state.c = ((p & 0x01) != 0)
            state.z = ((p & 0x02) != 0)
            state.i = ((p & 0x04) != 0)
            state.d = ((p & 0x08) != 0)
            state.v = ((p & 0x40) != 0)
            state.n = ((p & 0x80) != 0)
            state.cycle = 0
        } else {
            state.cycle -= 1
        }
    }

    //MARK: RLA*
    
    internal func rlaZeroPage() {
        rolZeroPage()
    }
    
    internal func rlaZeroPage2() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        loadA(state.a & state.data)
        state.cycle = 0
    }
    
    internal func rlaAbsolute() {
        rolAbsolute()
    }
    
    internal func rlaAbsolute2() {
        memory.writeByte(address, byte: state.data)
        loadA(state.a & state.data)
        state.cycle = 0
    }
    
    //MARK: ROL
    
    internal func rolAccumulator() {
        if idleReadImplied() {
            let hasCarry = state.c
            state.c = ((state.a & 0x80) != 0)
            loadA((state.a << 1) + (hasCarry ? 1 : 0))
            state.cycle = 0
        }
    }
    
    internal func rolZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        let hasCarry = state.c
        state.c = ((state.data & 0x80) != 0)
        state.data = (state.data << 1) + (hasCarry ? 1 : 0)
    }
    
    internal func rolAbsolute() {
        memory.writeByte(address, byte: state.data)
        let hasCarry = state.c
        state.c = ((state.data & 0x80) != 0)
        state.data = (state.data << 1) + (hasCarry ? 1 : 0)
    }
    
    //MARK: ROR
    
    internal func rorAccumulator() {
        if idleReadImplied() {
            let hasCarry = state.c
            state.c = ((state.a & 1) != 0)
            loadA((state.a >> 1) + (hasCarry ? 0x80 : 0))
            state.cycle = 0
        }
    }
    
    internal func rorZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        let hasCarry = state.c
        state.c = ((state.data & 1) != 0)
        state.data = (state.data >> 1) + (hasCarry ? 0x80 : 0)
    }
    
    internal func rorAbsolute() {
        memory.writeByte(address, byte: state.data)
        let hasCarry = state.c
        state.c = ((state.data & 1) != 0)
        state.data = (state.data >> 1) + (hasCarry ? 0x80 : 0)
    }
    
    //MARK: RRA*
    
    internal func rraZeroPage() {
        rorZeroPage()
    }
    
    internal func rraZeroPage2() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        adc(state.data)
        state.cycle = 0
    }
    
    internal func rraAbsolute() {
        rorAbsolute()
    }
    
    internal func rraAbsolute2() {
        memory.writeByte(address, byte: state.data)
        adc(state.data)
        state.cycle = 0
    }
    
    //MARK: RTI
    
    internal func rtiImplied() {
        if rdyLine.state {
            let p = memory.readByte(0x100 &+ state.sp)
            state.c = (p & 0x01 != 0)
            state.z = (p & 0x02 != 0)
            state.i = (p & 0x04 != 0)
            state.d = (p & 0x08 != 0)
            state.v = (p & 0x40 != 0)
            state.n = (p & 0x80 != 0)
            state.sp = state.sp &+ 1
        } else {
            state.cycle -= 1
        }
    }

    internal func rtiImplied2() {
        if rdyLine.state {
            pcl = memory.readByte(0x100 &+ state.sp)
            state.sp = state.sp &+ 1
        } else {
            state.cycle -= 1
        }
    }

    internal func rtiImplied3() {
        if rdyLine.state {
            pch = memory.readByte(0x100 &+ state.sp)
            state.cycle = 0
        } else {
            state.cycle -= 1
        }
    }

    //MARK: RTS
    
    internal func rtsImplied() {
        if rdyLine.state {
            pcl = memory.readByte(0x100 &+ state.sp)
            state.sp = state.sp &+ 1
        } else {
            state.cycle -= 1
        }
    }

    internal func rtsImplied2() {
        if rdyLine.state {
            pch = memory.readByte(0x100 &+ state.sp)
        } else {
            state.cycle -= 1
        }
    }

    internal func rtsImplied3() {
        state.pc += 1
        state.cycle = 0
    }
    
    //MARK: SAX*
    
    internal func saxZeroPage() {
        state.data = state.a & state.x
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.cycle = 0
    }
    
    internal func saxAbsolute() {
        state.data = state.a & state.x
        memory.writeByte(address, byte: state.data)
        state.cycle = 0
    }
    
    //MARK: SBC
    
    internal func sbc(_ value: UInt8) {
        if state.d {
            let tempA = UInt16(state.a)
            let sum = (tempA &- UInt16(value) &- (state.c ? 0 : 1))
            var lowNybble = (state.a & 0x0F) &- (value & 0x0F) &- (state.c ? 0 : 1)
            var highNybble = (state.a >> 4) &- (value >> 4)
            if lowNybble & 0x10 != 0 {
                lowNybble = lowNybble &- 6
                highNybble = highNybble &- 1
            }
            if highNybble & 0x10 != 0 {
                highNybble = highNybble &- 6
            }
            state.c = (sum < 0x100)
            state.v = (((tempA ^ sum) & 0x80) != 0 && ((tempA ^ UInt16(value)) & 0x80) != 0)
            state.z = (UInt8(truncatingBitPattern: sum) == 0)
            state.n = (sum & 0x80 != 0)
            state.a = (highNybble << 4) | (lowNybble & 0x0F)
        } else {
            let tempA = UInt16(state.a)
            let sum = (tempA &- UInt16(value) &- (state.c ? 0 : 1))
            state.c = (sum <= 0xFF)
            state.v = (((UInt16(state.a) ^ sum) & 0x80) != 0 && ((UInt16(state.a) ^ UInt16(value)) & 0x80) != 0)
            loadA(UInt8(truncatingBitPattern: sum))
        }
    }
    
    internal func sbcImmediate() {
        if loadDataImmediate() {
            sbc(state.data)
            state.cycle = 0
        }
    }
    
    internal func sbcZeroPage() {
        if loadDataZeroPage() {
            sbc(state.data)
            state.cycle = 0
        }
    }
    
    internal func sbcPageBoundary() {
        if loadDataAbsolute() {
            if state.pageBoundaryCrossed {
                state.addressHigh = state.addressHigh &+ 1
            } else {
                sbc(state.data)
                state.cycle = 0
            }
        }
    }
    
    internal func sbcAbsolute() {
        if loadDataAbsolute() {
            sbc(state.data)
            state.cycle = 0
        }
    }
    
    //MARK: SBX*
    
    internal func sbxImmediate() {
        if loadDataImmediate() {
            let value = state.a & state.x
            let diff = value &- state.data
            state.c = (value >= diff)
            loadX(diff)
            state.cycle = 0
        }
    }
    
    //MARK: SEC
    
    internal func secImplied() {
        if idleReadImplied() {
            state.c = true
            state.cycle = 0
        }
    }
    
    //MARK: SED
    
    internal func sedImplied() {
        if idleReadImplied() {
            state.d = true
            state.cycle = 0
        }
    }
    
    //MARK: SEI
    
    internal func seiImplied() {
        if idleReadImplied() {
            state.i = true
            state.cycle = 0
        }
    }
    
    //MARK: SHA*
    
    internal func shaAbsolute() {
        state.data = state.a & state.x & (state.addressHigh &+ 1)
        memory.writeByte(address, byte: state.data)
        if state.pageBoundaryCrossed {
            state.addressHigh = state.data
        }
        state.cycle = 0
    }
    
    //MARK: SHS*
    
    internal func shsAbsolute() {
        if rdyLine.state {
            memory.readByte(address)
            state.sp = state.x & state.a
            state.data = state.sp & (state.addressHigh &+ 1)
            memory.writeByte(address, byte: state.data)
            if state.pageBoundaryCrossed {
                state.addressHigh = state.data
            }
            state.cycle = 0
        } else {
            state.cycle -= 1
        }
    }

    //MARK: SHX*
    
    internal func shxAbsolute() {
        state.data = state.x & (state.addressHigh &+ 1)
        memory.writeByte(address, byte: state.data)
        if state.pageBoundaryCrossed {
            state.addressHigh = state.data
        }
        state.cycle = 0
    }
    
    //MARK: SHY*
    
    internal func shyAbsolute() {
        state.data = state.y & (state.addressHigh &+ 1)
        memory.writeByte(address, byte: state.data)
        if state.pageBoundaryCrossed {
            state.addressHigh = state.data
        }
        state.cycle = 0
    }
    
    //MARK: SLO*
    
    internal func sloZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.c = ((state.data & 0x80) != 0)
        state.data <<= 1
    }
    
    internal func sloZeroPage2() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        loadA(state.a | state.data)
        state.cycle = 0
    }
    
    internal func sloAbsolute() {
        memory.writeByte(address, byte: state.data)
        state.c = ((state.data & 0x80) != 0)
        state.data <<= 1
    }
    
    internal func sloAbsolute2() {
        memory.writeByte(address, byte: state.data)
        loadA(state.a | state.data)
        state.cycle = 0
    }
    
    //MARK: SRE*
    
    internal func sreZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.c = ((state.data & 0x01) != 0)
        state.data >>= 1
    }
    
    internal func sreZeroPage2() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        loadA(state.a ^ state.data)
        state.cycle = 0
    }
    
    internal func sreAbsolute() {
        memory.writeByte(address, byte: state.data)
        state.c = ((state.data & 0x01) != 0)
        state.data >>= 1
    }
    
    internal func sreAbsolute2() {
        memory.writeByte(address, byte: state.data)
        loadA(state.a ^ state.data)
        state.cycle = 0
    }
    
    //MARK: STA
    
    internal func staZeroPage() {
        state.data = state.a
        memory.writeByte(UInt16(state.addressLow), byte: state.a)
        state.cycle = 0
    }
    
    internal func staAbsolute() {
        state.data = state.a
        memory.writeByte(address, byte: state.data)
        state.cycle = 0
    }
    
    //MARK: STX
    
    internal func stxZeroPage() {
        state.data = state.x
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.cycle = 0
    }
    
    internal func stxAbsolute() {
        state.data = state.x
        memory.writeByte(address, byte: state.data)
        state.cycle = 0
    }
    
    //MARK: STY
    
    internal func styZeroPage() {
        state.data = state.y
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.cycle = 0
    }
    
    internal func styAbsolute() {
        state.data = state.y
        memory.writeByte(address, byte: state.data)
        state.cycle = 0
    }
    
    //MARK: TAX
    
    internal func taxImplied() {
        if idleReadImplied() {
            loadX(state.a)
            state.cycle = 0
        }
    }
    
    //MARK: TAY
    
    internal func tayImplied() {
        if idleReadImplied() {
            loadY(state.a)
            state.cycle = 0
        }
    }
    
    //MARK: TSX
    
    internal func tsxImplied() {
        if idleReadImplied() {
            loadX(state.sp)
            state.cycle = 0
        }
    }
    
    //MARK: TXA
    
    internal func txaImplied() {
        if idleReadImplied() {
            loadA(state.x)
            state.cycle = 0
        }
    }
    
    //MARK: TXS
    
    internal func txsImplied() {
        if idleReadImplied() {
            state.sp = state.x
            state.cycle = 0
        }
    }
    
    //MARK: TYA
    
    internal func tyaImplied() {
        if idleReadImplied() {
            loadA(state.y)
            state.cycle = 0
        }
    }
    
}
