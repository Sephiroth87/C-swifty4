//
//  CPU.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 30/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

import Foundation

internal struct CPUState: ComponentState {
    
    var pc: UInt16 = 0
    var isAtFetch = false
    var a: UInt8 = 0
    var x: UInt8 = 0
    var y: UInt8 = 0
    var sp: UInt8 = 0
    var c: Bool = false
    var z: Bool = false
    var i: Bool = false
    var d: Bool = false
    var b: Bool = true
    var v: Bool = false
    var n: Bool = false

    var portDirection: UInt8 = 0x2F
    var port: UInt8 = 0x37
    
    @available(*, deprecated) var irqTriggered = false //TODO: maybe we still need to keep track if the IRQ has been triggered?
    var nmiTriggered = false //TODO: see below
    var nmiLine = true
    var currentOpcode: UInt16 = 0
    var cycle = 0
    
    var data: UInt8 = 0
    var addressLow: UInt8 = 0
    var addressHigh: UInt8 = 0
    var pointer: UInt8 = 0
    var pageBoundaryCrossed = false
    
    mutating func update(dictionary: [String: AnyObject]) {
        pc = UInt16(dictionary["pc"] as! UInt)
        isAtFetch = dictionary["isAtFetch"] as! Bool
        a = UInt8(dictionary["a"] as! UInt)
        x = UInt8(dictionary["x"] as! UInt)
        y = UInt8(dictionary["y"] as! UInt)
        sp = UInt8(dictionary["sp"] as! UInt)
        c = dictionary["c"] as! Bool
        z = dictionary["z"] as! Bool
        i = dictionary["i"] as! Bool
        d = dictionary["d"] as! Bool
        b = dictionary["b"] as! Bool
        v = dictionary["v"] as! Bool
        n = dictionary["n"] as! Bool
        portDirection = UInt8(dictionary["portDirection"] as! UInt)
        port = UInt8(dictionary["port"] as! UInt)
        irqTriggered = dictionary["irqTriggered"] as! Bool
        nmiTriggered = dictionary["nmiTriggered"] as! Bool
        currentOpcode = UInt16(dictionary["currentOpcode"] as! UInt)
        cycle = dictionary["cycle"] as! Int
        data = UInt8(dictionary["data"] as! UInt)
        addressLow = UInt8(dictionary["addressLow"] as! UInt)
        addressHigh = UInt8(dictionary["addressHigh"] as! UInt)
        pointer = UInt8(dictionary["pointer"] as! UInt)
        pageBoundaryCrossed = dictionary["pageBoundaryCrossed"] as! Bool
    }

}

final internal class CPU: Component, IRQLineComponent {
    
    var state = CPUState()

    internal weak var irqLine: Line!
    internal weak var memory: Memory!
    internal var crashHandler: C64CrashHandler?

    private var pcl: UInt8 {
        set {
            state.pc = (state.pc & 0xFF00) | UInt16(newValue)
        }
        get {
            return UInt8(truncatingBitPattern: state.pc)
        }
    }
    private var pch: UInt8 {
        set {
            state.pc = (state.pc & 0x00FF) | UInt16(newValue) << 8
        }
        get {
            return UInt8(truncatingBitPattern: state.pc >> 8)
        }
    }

    internal var port: UInt8 {
        set {
            state.port = newValue | ~state.portDirection
        }
        get {
            return state.port
        }
    }
    var portDirection: UInt8 {
        set {
            state.portDirection = newValue
        }
        get {
            return state.portDirection
        }
    }

    private var address: UInt16 {
        get {
            return UInt16(state.addressHigh) << 8 | UInt16(state.addressLow)
        }
    }

    internal init(pc: UInt16) {
        self.state.pc = pc
    }
    
    //MARK: LineComponent
    
    func lineChanged(line: Line) {
    }
    
    //MARK: Running
    
    internal func executeInstruction() {
        if state.cycle++ == 0 {
            fetch()
            return
        }
        state.isAtFetch = false
        switch state.currentOpcode {
            // ADC
        case 0x69:
            adcImmediate()
        case 0x65:
            state.cycle == 2 ? zeroPage() : adcZeroPage()
        case 0x6D:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : adcAbsolute()
        case 0x7D:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteX() :
                state.cycle == 4 ? adcPageBoundary() : adcAbsolute()
        case 0x79:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteY() :
                state.cycle == 4 ? adcPageBoundary() : adcAbsolute()
        case 0x71:
            state.cycle == 2 ? indirectIndex() :
                state.cycle == 3 ? indirectIndex2() :
                state.cycle == 4 ? indirectY() :
                state.cycle == 5 ? adcPageBoundary() : adcAbsolute()
            // AND
        case 0x29:
            andImmediate()
        case 0x25:
            state.cycle == 2 ? zeroPage() : andZeroPage()
        case 0x35:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() : andZeroPage()
        case 0x2D:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : andAbsolute()
        case 0x3D:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteX() :
                state.cycle == 4 ? andPageBoundary() : andAbsolute()
        case 0x39:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteY() :
                state.cycle == 4 ? andPageBoundary() : andAbsolute()
            // ASL
        case 0x0A:
            aslAccumulator()
        case 0x06:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPage2() :
                state.cycle == 4 ? aslZeroPage() : zeroPageWriteUpdateNZ()
        case 0x16:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() :
                state.cycle == 4 ? zeroPage2() :
                state.cycle == 5 ? aslZeroPage() : zeroPageWriteUpdateNZ()
            // BCC
        case 0x90:
            state.cycle == 2 ? bccRelative() :
                state.cycle == 3 ? branch() : branchOverflow()
            // BCS
        case 0xB0:
            state.cycle == 2 ? bcsRelative() :
                state.cycle == 3 ? branch() : branchOverflow()
            // BEQ
        case 0xF0:
            state.cycle == 2 ? beqRelative() :
                state.cycle == 3 ? branch() : branchOverflow()
            // BIT
        case 0x24:
            state.cycle == 2 ? zeroPage() : bitZeroPage()
        case 0x2C:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : bitAbsolute()
            // BMI
        case 0x30:
            state.cycle == 2 ? bmiRelative() :
                state.cycle == 3 ? branch() : branchOverflow()
            // BNE 
        case 0xD0:
            state.cycle == 2 ? bneRelative() :
                state.cycle == 3 ? branch() : branchOverflow()
            // BPL
        case 0x10:
            state.cycle == 2 ? bplRelative() :
                state.cycle == 3 ? branch() : branchOverflow()
            // BVC
        case 0x50:
            state.cycle == 2 ? bvcRelative() :
                state.cycle == 3 ? branch() : branchOverflow()
            // BVS
        case 0x70:
            state.cycle == 2 ? bvsRelative() :
                state.cycle == 3 ? branch() : branchOverflow()
            // CLC
        case 0x18:
            clcImplied()
            // CLD
        case 0xD8:
            cldImplied()
            // CLI
        case 0x58:
            cliImplied()
            // CLV
        case 0xB8:
            clvImplied()
            // CMP
        case 0xC9:
            cmpImmediate()
        case 0xC5:
            state.cycle == 2 ? zeroPage() : cmpZeroPage()
        case 0xD5:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() : cmpZeroPage()
        case 0xCD:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : cmpAbsolute()
        case 0xDD:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteX() :
                state.cycle == 4 ? cmpPageBoundary() : cmpAbsolute()
        case 0xD9:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteY() :
                state.cycle == 4 ? cmpPageBoundary() : cmpAbsolute()
        case 0xC1:
            state.cycle == 2 ? indirectIndex() :
                state.cycle == 3 ? indirectX() :
                state.cycle == 4 ? indirectIndex2() :
                state.cycle == 5 ? indirectX2() : cmpAbsolute()
        case 0xD1:
            state.cycle == 2 ? indirectIndex() :
                state.cycle == 3 ? indirectIndex2() :
                state.cycle == 4 ? indirectY() :
                state.cycle == 5 ? cmpPageBoundary() : cmpAbsolute()
            // CPX
        case 0xE0:
            cpxImmediate()
        case 0xE4:
            state.cycle == 2 ? zeroPage() : cpxZeroPage()
        case 0xEC:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : cpxAbsolute()
            // CPY
        case 0xC0:
            cpyImmediate()
        case 0xC4:
            state.cycle == 2 ? zeroPage() : cpyZeroPage()
        case 0xCC:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : cpyAbsolute()
            // DEC
        case 0xC6:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPage2() :
                state.cycle == 4 ? decZeroPage() : zeroPageWriteUpdateNZ()
        case 0xD6:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() :
                state.cycle == 4 ? zeroPage2() :
                state.cycle == 5 ? decZeroPage() : zeroPageWriteUpdateNZ()
        case 0xCE:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() :
                state.cycle == 4 ? absolute3() :
                state.cycle == 5 ? decAbsolute() : absoluteWriteUpdateNZ()
        case 0xDE:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteX() :
                state.cycle == 4 ? absoluteFixPage() :
                state.cycle == 5 ? absolute3() :
                state.cycle == 6 ? decAbsolute() : absoluteWriteUpdateNZ()
            // DEX
        case 0xCA:
            dexImplied()
            // DEY
        case 0x88:
            deyImplied()
            // EOR
        case 0x49:
            eorImmediate()
        case 0x45:
            state.cycle == 2 ? zeroPage() : eorZeroPage()
        case 0x55:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() : eorZeroPage()
        case 0x4D:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : eorAbsolute()
        case 0x5D:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteX() :
                state.cycle == 4 ? eorPageBoundary() : eorAbsolute()
        case 0x59:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteY() :
                state.cycle == 4 ? eorPageBoundary() : eorAbsolute()
        case 0x51:
            state.cycle == 2 ? indirectIndex() :
                state.cycle == 3 ? indirectIndex2() :
                state.cycle == 4 ? indirectY() :
                state.cycle == 5 ? eorPageBoundary() : eorAbsolute()
            // INC
        case 0xE6:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPage2() :
                state.cycle == 4 ? incZeroPage() : zeroPageWriteUpdateNZ()
        case 0xF6:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() :
                state.cycle == 4 ? zeroPage2() :
                state.cycle == 5 ? incZeroPage() : zeroPageWriteUpdateNZ()
        case 0xEE:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() :
                state.cycle == 4 ? absolute3() :
                state.cycle == 5 ? incAbsolute() : absoluteWriteUpdateNZ()
        case 0xFE:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteX() :
                state.cycle == 4 ? absoluteFixPage() :
                state.cycle == 5 ? absolute3() :
                state.cycle == 6 ? incAbsolute() : absoluteWriteUpdateNZ()
            // INX
        case 0xE8:
            inxImplied()
            // INY
        case 0xC8:
            inyImplied()
            // JMP
        case 0x4C:
            state.cycle == 2 ? absolute() : jmpAbsolute()
        case 0x6C:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() :
                state.cycle == 4 ? indirect() : jmpIndirect()
            // JSR
        case 0x20:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? {}() :
                state.cycle == 4 ? pushPch() :
                state.cycle == 5 ? pushPcl() : jsrAbsolute()
            // LAX
        case 0xAF:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : laxAbsolute()
            // LDA
        case 0xA9:
            ldaImmediate()
        case 0xA5:
            state.cycle == 2 ? zeroPage() : ldaZeroPage()
        case 0xB5:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() : ldaZeroPage()
        case 0xAD:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : ldaAbsolute()
        case 0xBD:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteX() :
                state.cycle == 4 ? ldaPageBoundary() : ldaAbsolute()
        case 0xB9:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteY() :
                state.cycle == 4 ? ldaPageBoundary() : ldaAbsolute()
        case 0xA1:
            state.cycle == 2 ? indirectIndex() :
                state.cycle == 3 ? indirectX() :
                state.cycle == 4 ? indirectIndex2() :
                state.cycle == 5 ? indirectX2() : ldaAbsolute()
        case 0xB1:
            state.cycle == 2 ? indirectIndex() :
                state.cycle == 3 ? indirectIndex2() :
                state.cycle == 4 ? indirectY() :
                state.cycle == 5 ? ldaPageBoundary() : ldaAbsolute()
            // LDX
        case 0xA2:
            ldxImmediate()
        case 0xA6:
            state.cycle == 2 ? zeroPage() : ldxZeroPage()
        case 0xB6:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageY() : ldxZeroPage()
        case 0xAE:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : ldxAbsolute()
        case 0xBE:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteY() :
                state.cycle == 4 ? ldxPageBoundary() : ldxAbsolute()
            // LDY
        case 0xA0:
            ldyImmediate()
        case 0xA4:
            state.cycle == 2 ? zeroPage() : ldyZeroPage()
        case 0xB4:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() : ldyZeroPage()
        case 0xAC:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : ldyAbsolute()
        case 0xBC:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteX() :
                state.cycle == 4 ? ldyPageBoundary() : ldyAbsolute()
            // LSR
        case 0x4A:
            lsrAccumulator()
        case 0x46:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPage2() :
                state.cycle == 4 ? lsrZeroPage() : zeroPageWriteUpdateNZ()
        case 0x56:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() :
                state.cycle == 4 ? zeroPage2() :
                state.cycle == 5 ? lsrZeroPage() : zeroPageWriteUpdateNZ()
            // NOP
        case 0xEA, 0x5A, 0x7A:
            nop()
        case 0x44:
            state.cycle == 2 ? zeroPage() : nopZeroPage()
        case 0x14:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() : nopZeroPage()
        case 0x82, 0xE2:
            nopImmediate()
            // ORA
        case 0x09:
            oraImmediate()
        case 0x05:
            state.cycle == 2 ? zeroPage() : oraZeroPage()
        case 0x0D:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : oraAbsolute()
        case 0x1D:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteX() :
                state.cycle == 4 ? oraPageBoundary() : oraAbsolute()
            // PHA
        case 0x48:
            state.cycle == 2 ? implied() : phaImplied()
            // PHP
        case 0x08:
            state.cycle == 2 ? implied() : phpImplied()
            // PLA
        case 0x68:
            state.cycle == 2 ? implied() :
                state.cycle == 3 ? implied2() : plaImplied()
            // PLP
        case 0x28:
            state.cycle == 2 ? implied() :
                state.cycle == 3 ? implied2() : plpImplied()
            // ROL
        case 0x2A:
            rolAccumulator()
        case 0x26:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPage2() :
                state.cycle == 4 ? rolZeroPage() : zeroPageWriteUpdateNZ()
        case 0x2E:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() :
                state.cycle == 4 ? absolute3() :
                state.cycle == 5 ? rolAbsolute() : absoluteWriteUpdateNZ()
            // ROR
        case 0x6A:
            rorAccumulator()
        case 0x66:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPage2() :
                state.cycle == 4 ? rorZeroPage() : zeroPageWriteUpdateNZ()
        case 0x76:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() :
                state.cycle == 4 ? zeroPage2() :
                state.cycle == 5 ? rorZeroPage() : zeroPageWriteUpdateNZ()
        case 0x6E:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() :
                state.cycle == 4 ? absolute3() :
                state.cycle == 5 ? rorAbsolute() : absoluteWriteUpdateNZ()
            // RTI
        case 0x40:
            state.cycle == 2 ? implied() :
                state.cycle == 3 ? implied2() :
                state.cycle == 4 ? rtiImplied() :
                state.cycle == 5 ? rtiImplied2() : rtiImplied3()
            // RTS
        case 0x60:
            state.cycle == 2 ? implied() :
                state.cycle == 3 ? implied2() :
                state.cycle == 4 ? rtsImplied() :
                state.cycle == 5 ? rtsImplied2() : rtsImplied3()
            // SBC
        case 0xE9:
            sbcImmediate()
        case 0xE5:
            state.cycle == 2 ? zeroPage() : sbcZeroPage()
        case 0xF5:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() : sbcZeroPage()
        case 0xED:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() :
                state.cycle == 4 ? sbcAbsolute() : sbcAbsolute2()
        case 0xFD:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteX() :
                state.cycle == 4 ? sbcAbsolute() : sbcAbsolute2()
        case 0xF9:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteY() :
                state.cycle == 4 ? sbcAbsolute() : sbcAbsolute2()
        case 0xF1:
            state.cycle == 2 ? indirectIndex() :
                state.cycle == 3 ? indirectIndex2() :
                state.cycle == 4 ? indirectY() :
                state.cycle == 5 ? sbcAbsolute() : sbcAbsolute2()
            // SEC
        case 0x38:
            secImplied()
        case 0xF8:
            sedImplied()
            // SEI
        case 0x78:
            seiImplied()
            // STA
        case 0x85:
            state.cycle == 2 ? zeroPage() : staZeroPage()
        case 0x95:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() : staZeroPage()
        case 0x8D:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : staAbsolute()
        case 0x9D:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteX() :
                state.cycle == 4 ? absoluteFixPage() : staAbsolute()
        case 0x99:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absoluteY() :
                state.cycle == 4 ? absoluteFixPage() : staAbsolute()
        case 0x81:
            state.cycle == 2 ? indirectIndex() :
                state.cycle == 3 ? indirectX() :
                state.cycle == 4 ? indirectIndex2() :
                state.cycle == 5 ? indirectX2() : staAbsolute()
        case 0x91:
            state.cycle == 2 ? indirectIndex() :
                state.cycle == 3 ? indirectIndex2() :
                state.cycle == 4 ? indirectY() :
                state.cycle == 5 ? absoluteFixPage() : staAbsolute()
            // STX
        case 0x86:
            state.cycle == 2 ? zeroPage() : stxZeroPage()
        case 0x96:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageY() : styZeroPage()
        case 0x8E:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : stxAbsolute()
            // STY
        case 0x84:
            state.cycle == 2 ? zeroPage() : styZeroPage()
        case 0x94:
            state.cycle == 2 ? zeroPage() :
                state.cycle == 3 ? zeroPageX() : styZeroPage()
        case 0x8C:
            state.cycle == 2 ? absolute() :
                state.cycle == 3 ? absolute2() : styAbsolute()
            // TAX
        case 0xAA:
            taxImplied()
            // TAY
        case 0xA8:
            tayImplied()
            // TSX
        case 0xBA:
            tsxImplied()
            // TXA
        case 0x8A:
            txaImplied()
            // TXS
        case 0x9a:
            txsImplied()
            // TYA
        case 0x98:
            tyaImplied()
            // IRQ
        case 0xFFFE:
            state.cycle == 2 ? implied() :
                state.cycle == 3 ? pushPch() :
                state.cycle == 4 ? pushPcl() :
                state.cycle == 5 ? interrupt() :
                state.cycle == 6 ? nmi() : nmi2()
        case 0xFFFF:
            state.cycle == 2 ? implied() :
                state.cycle == 3 ? pushPch() :
                state.cycle == 4 ? pushPcl() :
                state.cycle == 5 ? interrupt() :
                state.cycle == 6 ? irq() : irq2()
        default:
            let opcodeString = String(state.currentOpcode, radix: 16, uppercase: true)
            let pcString = String((state.pc &- UInt16(1)), radix: 16, uppercase: true)
            crashHandler?("Unknown opcode: " + opcodeString + " pc: " + pcString)
        }
    }
    
    @available(*, deprecated) internal func setIRQLine() {
        state.irqTriggered = true
    }

    //TODO: NMI is connected to multiple sources so it should be treated like an actual line (like IEC)
    internal func setNMILine(line: Bool) {
        if !line && state.nmiLine {
            state.nmiTriggered = true
        }
        state.nmiLine = line
    }
    
    internal func setOverflow() {
        state.v = true
    }
    
    internal func debugInfo() -> [String: String] {
        let description: String = {
            switch state.currentOpcode {
            case 0x69: return String(format: "ADC #%02x", self.memory.readByte(state.pc))
            case 0x65: return String(format: "ADC %02x", self.memory.readByte(state.pc))
            case 0x6D: return String(format: "ADC %04x", self.memory.readWord(state.pc))
            case 0x7D: return String(format: "ADC %04x,X", self.memory.readWord(state.pc))
            case 0x79: return String(format: "ADC %04x,Y", self.memory.readWord(state.pc))
            case 0x71: return String(format: "ADC (%02x),Y", self.memory.readByte(state.pc))
            case 0x29: return String(format: "AND #%02x", self.memory.readByte(state.pc))
            case 0x25: return String(format: "AND %02x", self.memory.readByte(state.pc))
            case 0x35: return String(format: "AND %02x,X", self.memory.readByte(state.pc))
            case 0x2D: return String(format: "AND %04x", self.memory.readWord(state.pc))
            case 0x3D: return String(format: "AND %04x,X", self.memory.readWord(state.pc))
            case 0x39: return String(format: "AND %04x,Y", self.memory.readWord(state.pc))
            case 0x0A: return "ASL"
            case 0x06: return String(format: "ASL %02x", self.memory.readByte(state.pc))
            case 0x16: return String(format: "ASL %02x,X", self.memory.readByte(state.pc))
            case 0x90: return String(format: "BCC %02x", self.memory.readByte(state.pc))
            case 0xB0: return String(format: "BCS %02x", self.memory.readByte(state.pc))
            case 0xF0: return String(format: "BEQ %02x", self.memory.readByte(state.pc))
            case 0x24: return String(format: "BIT %02x", self.memory.readByte(state.pc))
            case 0x2C: return String(format: "BIT %04x", self.memory.readWord(state.pc))
            case 0x30: return String(format: "BMI %02x", self.memory.readByte(state.pc))
            case 0xD0: return String(format: "BNE %02x", self.memory.readByte(state.pc))
            case 0x10: return String(format: "BPL %02x", self.memory.readByte(state.pc))
            case 0x50: return String(format: "BVC %02x", self.memory.readByte(state.pc))
            case 0x70: return String(format: "BVS %02x", self.memory.readByte(state.pc))
            case 0x18: return "CLC"
            case 0xD8: return "CLD"
            case 0x58: return "CLI"
            case 0xB8: return "CLV"
            case 0xC9: return String(format: "CMP #%02x", self.memory.readByte(state.pc))
            case 0xC5: return String(format: "CMP %02x", self.memory.readByte(state.pc))
            case 0xD5: return String(format: "CMP %02x,X", self.memory.readByte(state.pc))
            case 0xCD: return String(format: "CMP %04x", self.memory.readWord(state.pc))
            case 0xDD: return String(format: "CMP %04x,X", self.memory.readWord(state.pc))
            case 0xD9: return String(format: "CMP %04x,Y", self.memory.readWord(state.pc))
            case 0xC1: return String(format: "CMP (%02x,X)", self.memory.readByte(state.pc))
            case 0xD1: return String(format: "CMP (%02x),Y", self.memory.readByte(state.pc))
            case 0xE0: return String(format: "CPX #%02x", self.memory.readByte(state.pc))
            case 0xE4: return String(format: "CPX %02x", self.memory.readByte(state.pc))
            case 0xEC: return String(format: "CPX %04x", self.memory.readWord(state.pc))
            case 0xC0: return String(format: "CPY #%02x", self.memory.readByte(state.pc))
            case 0xC4: return String(format: "CPY %02x", self.memory.readByte(state.pc))
            case 0xCC: return String(format: "CPY %04x", self.memory.readWord(state.pc))
            case 0xC6: return String(format: "DEC %02x", self.memory.readByte(state.pc))
            case 0xD6: return String(format: "DEC %02x,X", self.memory.readByte(state.pc))
            case 0xCE: return String(format: "DEC %04x", self.memory.readWord(state.pc))
            case 0xDE: return String(format: "DEC %04x,X", self.memory.readWord(state.pc))
            case 0xCA: return "DEX"
            case 0x88: return "DEY"
            case 0x49: return String(format: "EOR #%02x", self.memory.readByte(state.pc))
            case 0x45: return String(format: "EOR %02x", self.memory.readByte(state.pc))
            case 0x55: return String(format: "EOR %02x,X", self.memory.readByte(state.pc))
            case 0x4D: return String(format: "EOR %04x", self.memory.readWord(state.pc))
            case 0x5D: return String(format: "EOR %04x,X", self.memory.readWord(state.pc))
            case 0x59: return String(format: "EOR %04x,Y", self.memory.readWord(state.pc))
            case 0x51: return String(format: "EOR (%02x),Y", self.memory.readByte(state.pc))
            case 0xE6: return String(format: "INC %02x", self.memory.readByte(state.pc))
            case 0xF6: return String(format: "INC %02x,X", self.memory.readByte(state.pc))
            case 0xEE: return String(format: "INC %04x", self.memory.readWord(state.pc))
            case 0xFE: return String(format: "INC %04x,X", self.memory.readWord(state.pc))
            case 0xE8: return "INX"
            case 0xC8: return "INY"
            case 0x4C: return String(format: "JMP %04x", self.memory.readWord(state.pc))
            case 0x6C: return String(format: "JMP (%04x)", self.memory.readWord(state.pc))
            case 0x20: return String(format: "JSR %04x", self.memory.readWord(state.pc))
            case 0xAF: return String(format: "LAX* %04x", self.memory.readWord(state.pc))
            case 0xA9: return String(format: "LDA #%02x", self.memory.readByte(state.pc))
            case 0xA5: return String(format: "LDA %02x", self.memory.readByte(state.pc))
            case 0xB5: return String(format: "LDA %02x,X", self.memory.readByte(state.pc))
            case 0xAD: return String(format: "LDA %04x", self.memory.readWord(state.pc))
            case 0xBD: return String(format: "LDA %04x,X", self.memory.readWord(state.pc))
            case 0xB9: return String(format: "LDA %04x,Y", self.memory.readWord(state.pc))
            case 0xA1: return String(format: "LDA (%02x,X)", self.memory.readByte(state.pc))
            case 0xB1: return String(format: "LDA (%02x),Y", self.memory.readByte(state.pc))
            case 0xA2: return String(format: "LDX #%02x", self.memory.readByte(state.pc))
            case 0xA6: return String(format: "LDX %02x", self.memory.readByte(state.pc))
            case 0xB6: return String(format: "LDX %02x,Y", self.memory.readByte(state.pc))
            case 0xAE: return String(format: "LDX %04x", self.memory.readWord(state.pc))
            case 0xBE: return String(format: "LDX %04x,Y", self.memory.readWord(state.pc))
            case 0xA0: return String(format: "LDY #%02x", self.memory.readByte(state.pc))
            case 0xA4: return String(format: "LDY %02x", self.memory.readByte(state.pc))
            case 0xB4: return String(format: "LDY %02x,X", self.memory.readByte(state.pc))
            case 0xAC: return String(format: "LDY %04x", self.memory.readWord(state.pc))
            case 0xBC: return String(format: "LDY %04x,X", self.memory.readWord(state.pc))
            case 0x4A: return "LSR"
            case 0x46: return String(format: "LSR %02x", self.memory.readByte(state.pc))
            case 0x56: return String(format: "LSR %02x,X", self.memory.readByte(state.pc))
            case 0xEA: return "NOP"
            case 0x5A: return "NOP*"
            case 0x7A: return "NOP*"
            case 0x44: return String(format: "NOP* %02x", self.memory.readByte(state.pc))
            case 0x14: return String(format: "NOP* %02x,X", self.memory.readByte(state.pc))
            case 0x82: return String(format: "NOP* #%02x", self.memory.readByte(state.pc))
            case 0xE2: return String(format: "NOP* #%02x", self.memory.readByte(state.pc))
            case 0x09: return String(format: "ORA #%02x", self.memory.readByte(state.pc))
            case 0x05: return String(format: "ORA %02x", self.memory.readByte(state.pc))
            case 0x0D: return String(format: "ORA %04x", self.memory.readWord(state.pc))
            case 0x3D: return String(format: "ORA %04x,X", self.memory.readWord(state.pc))
            case 0x48: return "PHA"
            case 0x08: return "PHP"
            case 0x68: return "PLA"
            case 0x28: return "PLP"
            case 0x2A: return "ROL"
            case 0x26: return String(format: "ROL %02x", self.memory.readByte(state.pc))
            case 0x2E: return String(format: "ROL %04x", self.memory.readWord(state.pc))
            case 0x6A: return "ROR"
            case 0x66: return String(format: "ROR %02x", self.memory.readByte(state.pc))
            case 0x76: return String(format: "ROR %02x,X", self.memory.readByte(state.pc))
            case 0x6E: return String(format: "ROR %04x", self.memory.readWord(state.pc))
            case 0x40: return "RTI"
            case 0x60: return "RTS"
            case 0xE9: return String(format: "SBC #%02x", self.memory.readByte(state.pc))
            case 0xE5: return String(format: "SBC %02x", self.memory.readByte(state.pc))
            case 0xF5: return String(format: "SBC %02x,X", self.memory.readByte(state.pc))
            case 0xED: return String(format: "SBC %04x", self.memory.readWord(state.pc))
            case 0xFD: return String(format: "SBC %04x,X", self.memory.readWord(state.pc))
            case 0xF9: return String(format: "SBC %04x,Y", self.memory.readWord(state.pc))
            case 0xF1: return String(format: "SBC (%02x),Y", self.memory.readByte(state.pc))
            case 0x38: return "SEC"
            case 0xF8: return "SED"
            case 0x78: return "SEI"
            case 0x85: return String(format: "STA %02x", self.memory.readByte(state.pc))
            case 0x95: return String(format: "STA %02x,X", self.memory.readByte(state.pc))
            case 0x8D: return String(format: "STA %04x", self.memory.readWord(state.pc))
            case 0x9D: return String(format: "STA %04x,X", self.memory.readWord(state.pc))
            case 0x99: return String(format: "STA %04x,Y", self.memory.readWord(state.pc))
            case 0x81: return String(format: "STA (%02x,X)", self.memory.readByte(state.pc))
            case 0x91: return String(format: "STA (%02x),Y", self.memory.readByte(state.pc))
            case 0x86: return String(format: "STX %02x", self.memory.readByte(state.pc))
            case 0x96: return String(format: "STX %02x,Y", self.memory.readByte(state.pc))
            case 0x8E: return String(format: "STX %04x", self.memory.readWord(state.pc))
            case 0x84: return String(format: "STY %02x", self.memory.readByte(state.pc))
            case 0x94: return String(format: "STY %02x,X", self.memory.readByte(state.pc))
            case 0x8C: return String(format: "STY %04x", self.memory.readWord(state.pc))
            case 0xAA: return "TAX"
            case 0xA8: return "TAY"
            case 0xBA: return "TSX"
            case 0x8A: return "TXA"
            case 0x9a: return "TXS"
            case 0x98: return "TYA"
            default: return String(format: "Unknown opcode: %02x", state.currentOpcode)
            }
            }()
        return ["pc": String(format: "%04x", state.pc &- UInt16(1)),
            "a": String(format: "%02x", state.a),
            "x": String(format: "%02x", state.x),
            "y": String(format: "%02x", state.y),
            "sp": String(format: "%02x", state.sp),
            "sr.n": state.n ? "✓" : " ",
            "sr.v": state.v ? "✓" : " ",
            "sr.b": state.b ? "✓" : " ",
            "sr.d": state.d ? "✓" : " ",
            "sr.i": state.i ? "✓" : " ",
            "sr.z": state.z ? "✓" : " ",
            "sr.c": state.c ? "✓" : " ",
            "description": description
        ]
    }
    
    //MARK: Helpers
    
    private func updateNFlag(value: UInt8) {
        state.n = (value & 0x80 != 0)
    }
    
    private func updateZFlag(value: UInt8) {
        state.z = (value == 0)
    }
    
    private func loadA(value: UInt8) {
        state.a = value
        state.z = (value == 0)
        state.n = (value & 0x80 != 0)
    }
    
    private func loadX(value: UInt8) {
        state.x = value
        state.z = (value == 0)
        state.n = (value & 0x80 != 0)
    }
    
    private func loadY(value: UInt8) {
        state.y = value
        state.z = (value == 0)
        state.n = (value & 0x80 != 0)
    }
    
    private func fetch() {
        if state.nmiTriggered {
            state.nmiTriggered = false
            state.currentOpcode = 0xFFFE
            return
        }
        //IRQ is level sensitive, so it's always trigger as long as the line is pulled down
        if !irqLine.state && !state.i {
            state.currentOpcode = 0xFFFF
            return
        }
        if state.irqTriggered && !state.i {
            state.irqTriggered = false
            state.currentOpcode = 0xFFFF
            return
        }
        state.isAtFetch = true
        state.currentOpcode = UInt16(memory.readByte(state.pc))
        state.pc = state.pc &+ UInt16(1)
    }
    
    private func pushPch() {
        memory.writeByte(0x100 &+ state.sp, byte: pch)
        state.sp = state.sp &- 1
    }
    
    private func pushPcl() {
        memory.writeByte(0x100 &+ state.sp, byte: pcl)
        state.sp = state.sp &- 1
    }
    
    //MARK: Interrupts

    private func interrupt() {
        let p = UInt8((state.c ? 0x01 : 0) |
            (state.z ? 0x02 : 0) |
            (state.i ? 0x04 : 0) |
            (state.d ? 0x08 : 0) |
            //                (b ? 0x10 : 0) | b is 0 on IRQ
            0x20 |
            (state.v ? 0x40 : 0) |
            (state.n ? 0x80 : 0))
        memory.writeByte(0x100 &+ state.sp, byte: p)
        state.sp = state.sp &- 1
        state.i = true
    }

    private func irq() {
        state.data = memory.readByte(0xFFFE)
    }
    
    private func irq2() {
        pcl = state.data
        pch = memory.readByte(0xFFFF)
        state.cycle = 0
    }
    
    private func nmi() {
        state.data = memory.readByte(0xFFFA)
    }
    
    private func nmi2() {
        pcl = state.data
        pch = memory.readByte(0xFFFB)
        state.cycle = 0
    }
    
    //MARK: Opcodes
    
    //MARK: Addressing
    
    private func zeroPage() {
        state.addressLow = memory.readByte(state.pc++)
    }
    
    private func zeroPage2() {
        state.data = memory.readByte(UInt16(state.addressLow))
    }
    
    private func zeroPageWriteUpdateNZ() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.z = (state.data == 0)
        state.n = (state.data & 0x80 != 0)
        state.cycle = 0
    }
    
    private func zeroPageX() {
        state.data = memory.readByte(UInt16(state.addressLow))
        state.addressLow = state.addressLow &+ state.x
    }
    
    private func zeroPageY() {
        state.data = memory.readByte(UInt16(state.addressLow))
        state.addressLow = state.addressLow &+ state.y
    }
    
    private func absolute() {
        state.addressLow = memory.readByte(state.pc++)
    }
    
    private func absolute2() {
        state.addressHigh = memory.readByte(state.pc++)
    }
    
    private func absolute3() {
        state.data = memory.readByte(address)
    }
    
    private func absoluteWriteUpdateNZ() {
        memory.writeByte(address, byte: state.data)
        state.z = (state.data == 0)
        state.n = (state.data & 0x80 != 0)
        state.cycle = 0
    }
    
    private func absoluteX() {
        state.addressHigh = memory.readByte(state.pc++)
        state.pageBoundaryCrossed = (UInt16(state.addressLow) &+ state.x >= 0x100)
        state.addressLow = state.addressLow &+ state.x
    }
    
    private func absoluteY() {
        state.addressHigh = memory.readByte(state.pc++)
        state.pageBoundaryCrossed = (UInt16(state.addressLow) &+ state.y >= 0x100)
        state.addressLow = state.addressLow &+ state.y
    }
    
    private func absoluteFixPage() {
        memory.readByte(address)
        if state.pageBoundaryCrossed {
            state.addressHigh = state.addressHigh &+ 1
        }
    }
    
    private func indirect() {
        state.data = memory.readByte(address)
    }
    
    private func indirectIndex() {
        state.pointer = memory.readByte(state.pc++)
    }
    
    private func indirectIndex2() {
        state.addressLow = memory.readByte(UInt16(state.pointer++))
    }
    
    private func indirectX() {
        memory.readByte(UInt16(state.pointer))
        state.pointer = state.pointer &+ state.x
    }
    
    private func indirectX2() {
        state.addressHigh = memory.readByte(UInt16(state.pointer++))
    }
    
    private func indirectY() {
        state.addressHigh = memory.readByte(UInt16(state.pointer++))
        state.pageBoundaryCrossed = (UInt16(state.addressLow) &+ state.y >= 0x100)
        state.addressLow = state.addressLow &+ state.y
    }
    
    private func implied() {
        memory.readByte(state.pc)
    }
    
    private func implied2() {
        state.sp = state.sp &+ 1
    }
    
    //MARK: ADC
    
    private func adc(value: UInt8) {
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
    
    private func adcImmediate() {
        state.data = memory.readByte(state.pc++)
        adc(state.data)
        state.cycle = 0
    }
    
    private func adcZeroPage() {
        state.data = memory.readByte(UInt16(state.addressLow))
        adc(state.data)
        state.cycle = 0
    }
    
    private func adcPageBoundary() {
        state.data = memory.readByte(address)
        if state.pageBoundaryCrossed {
            state.addressHigh = state.addressHigh &+ 1
        } else {
            adc(state.data)
            state.cycle = 0
        }
    }
    
    private func adcAbsolute() {
        state.data = memory.readByte(address)
        adc(state.data)
        state.cycle = 0
    }
    
    //MARK: AND
    
    private func andImmediate() {
        state.data = memory.readByte(state.pc++)
        loadA(state.a & state.data)
        state.cycle = 0
    }
    
    private func andZeroPage() {
        state.data = memory.readByte(UInt16(state.addressLow))
        loadA(state.a & state.data)
        state.cycle = 0
    }
    
    private func andPageBoundary() {
        state.data = memory.readByte(address)
        if state.pageBoundaryCrossed {
            state.addressHigh = state.addressHigh &+ 1
        } else {
            loadA(state.a & state.data)
            state.cycle = 0
        }
    }
    
    private func andAbsolute() {
        state.data = memory.readByte(address)
        loadA(state.a & state.data)
        state.cycle = 0
    }
    
    //MARK: ASL
    
    private func aslAccumulator() {
        memory.readByte(state.pc)
        state.c = ((state.a & 0x80) != 0)
        loadA(state.a << 1)
        state.cycle = 0
    }
    
    private func aslZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.c = ((state.data & 0x80) != 0)
        state.data = state.data << 1
    }

    //MARK: BCC
    
    private func branch() {
        memory.readByte(state.pc)
        let oldPch = pch
        state.pc = state.pc &+ Int8(bitPattern: state.data)
        if pch == oldPch {
            //TODO: delay IRQs
            state.cycle = 0
        }
    }
    
    private func branchOverflow() {
        if state.data & 0x80 != 0 {
            memory.readByte(state.pc &+ UInt16(0x100))
        } else {
            memory.readByte(state.pc &- UInt16(0x100))
        }
        state.cycle = 0
    }
    
    private func bccRelative() {
        state.data = memory.readByte(state.pc++)
        if state.c {
            state.cycle = 0
        }
    }
    
    //MARK: BCS
    
    private func bcsRelative() {
        state.data = memory.readByte(state.pc++)
        if !state.c {
            state.cycle = 0
        }
    }
    
    //MARK: BEQ
    
    private func beqRelative() {
        state.data = memory.readByte(state.pc++)
        if !state.z {
            state.cycle = 0
        }
    }
    
    //MARK: BIT

    private func bitZeroPage() {
        state.data = memory.readByte(UInt16(state.addressLow))
        state.n = ((state.data & 128) != 0)
        state.v = ((state.data & 64) != 0)
        state.z = ((state.data & state.a) == 0)
        state.cycle = 0
    }
    
    private func bitAbsolute() {
        state.data = memory.readByte(address)
        state.n = ((state.data & 128) != 0)
        state.v = ((state.data & 64) != 0)
        state.z = ((state.data & state.a) == 0)
        state.cycle = 0
    }
    
    //MARK: BMI
    
    private func bmiRelative() {
        state.data = memory.readByte(state.pc++)
        if !state.n {
            state.cycle = 0
        }
    }
    
    //MARK: BNE
    
    private func bneRelative() {
        state.data = memory.readByte(state.pc++)
        if state.z {
            state.cycle = 0
        }
    }

    //MARK: BPL
    
    private func bplRelative() {
        state.data = memory.readByte(state.pc++)
        if state.n {
            state.cycle = 0
        }
    }
    
    //MARK: BVC
    
    private func bvcRelative() {
        state.data = memory.readByte(state.pc++)
        if state.v {
            state.cycle = 0
        }
    }
    
    //MARK: BVS
    
    private func bvsRelative() {
        state.data = memory.readByte(state.pc++)
        if !state.v {
            state.cycle = 0
        }
    }
    
    //MARK: CLC
    
    private func clcImplied() {
        memory.readByte(state.pc)
        state.c = false
        state.cycle = 0
    }
    
    //MARK: CLD
    
    private func cldImplied() {
        memory.readByte(state.pc)
        state.d = false
        state.cycle = 0
    }
    
    //MARK: CLI
    
    private func cliImplied() {
        memory.readByte(state.pc)
        state.i = false
        state.cycle = 0
    }
    
    //MARK: CLV
    
    private func clvImplied() {
        memory.readByte(state.pc)
        state.v = false
        state.cycle = 0
    }
    
    //MARK: CMP
    
    private func cmp(value1: UInt8, _ value2: UInt8) {
        let diff = value1 &- value2
        state.z = (diff == 0)
        state.n = (diff & 0x80 != 0)
        state.c = (value1 >= value2)
    }
    
    private func cmpImmediate() {
        state.data = memory.readByte(state.pc++)
        cmp(state.a, state.data)
        state.cycle = 0
    }
    
    private func cmpZeroPage() {
        state.data = memory.readByte(UInt16(state.addressLow))
        cmp(state.a, state.data)
        state.cycle = 0
    }

    private func cmpAbsolute() {
        state.data = memory.readByte(address)
        cmp(state.a, state.data)
        state.cycle = 0
    }
    
    private func cmpPageBoundary() {
        state.data = memory.readByte(address)
        if state.pageBoundaryCrossed {
            state.addressHigh = state.addressHigh &+ 1
        } else {
            cmp(state.a, state.data)
            state.cycle = 0
        }
    }
    
    //MARK: CPX
    
    private func cpxImmediate() {
        state.data = memory.readByte(state.pc++)
        cmp(state.x, state.data)
        state.cycle = 0
    }

    private func cpxZeroPage() {
        state.data = memory.readByte(UInt16(state.addressLow))
        cmp(state.x, state.data)
        state.cycle = 0
    }
    
    private func cpxAbsolute() {
        state.data = memory.readByte(address)
        cmp(state.x, state.data)
        state.cycle = 0
    }
    
    //MARK: CPY
    
    private func cpyImmediate() {
        state.data = memory.readByte(state.pc++)
        cmp(state.y, state.data)
        state.cycle = 0
    }

    private func cpyZeroPage() {
        state.data = memory.readByte(UInt16(state.addressLow))
        cmp(state.y, state.data)
        state.cycle = 0
    }
    
    private func cpyAbsolute() {
        state.data = memory.readByte(address)
        cmp(state.y, state.data)
        state.cycle = 0
    }
    
    //MARK: DEC
    
    private func decZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.data = state.data &- 1
    }
    
    private func decAbsolute() {
        memory.writeByte(address, byte: state.data)
        state.data = state.data &- 1
    }
    
    //MARK: DEX
    
    private func dexImplied() {
        loadX(state.x &- 1)
        state.cycle = 0
    }
    
    //MARK: DEY
    
    private func deyImplied() {
        loadY(state.y &- 1)
        state.cycle = 0
    }
    
    //MARK: EOR
    
    private func eorImmediate() {
        state.data = memory.readByte(state.pc++)
        loadA(state.a ^ state.data)
        state.cycle = 0
    }

    private func eorZeroPage() {
        state.data = memory.readByte(UInt16(state.addressLow))
        loadA(state.a ^ state.data)
        state.cycle = 0
    }
    
    private func eorAbsolute() {
        state.data = memory.readByte(address)
        loadA(state.a ^ state.data)
        state.cycle = 0
    }
    
    private func eorPageBoundary() {
        state.data = memory.readByte(address)
        if state.pageBoundaryCrossed {
            state.addressHigh = state.addressHigh &+ 1
        } else {
            loadA(state.a ^ state.data)
            state.cycle = 0
        }
    }
    
    //MARK: INC

    private func incZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.data = state.data &+ 1
    }
    
    private func incAbsolute() {
        memory.writeByte(address, byte: state.data)
        state.data = state.data &+ 1
    }
    
    //MARK: INX
    
    private func inxImplied() {
        memory.readByte(state.pc)
        loadX(state.x &+ 1)
        state.cycle = 0
    }
    
    //MARK: INY
    
    private func inyImplied() {
        memory.readByte(state.pc)
        loadY(state.y &+ 1)
        state.cycle = 0
    }
    
    //MARK: JMP
    
    private func jmpAbsolute() {
        state.addressHigh = memory.readByte(state.pc)
        state.pc = address
        state.cycle = 0
    }

    private func jmpIndirect() {
        pcl = state.data
        state.addressLow = state.addressLow &+ 1
        pch = memory.readByte(address)
        state.cycle = 0
    }
    
    //MARK: JSR
    
    private func jsrAbsolute() {
        state.addressHigh = memory.readByte(state.pc)
        state.pc = address
        state.cycle = 0
    }
    
    //MARK: LAX
    
    private func laxAbsolute() {
        state.data = memory.readByte(address)
        loadA(state.data)
        loadX(state.data)
        state.cycle = 0
    }
    
    //MARK: LDA
    
    private func ldaImmediate() {
        loadA(memory.readByte(state.pc++))
        state.cycle = 0
    }
    
    private func ldaZeroPage() {
        state.data = memory.readByte(UInt16(state.addressLow))
        loadA(state.data)
        state.cycle = 0
    }

    private func ldaAbsolute() {
        state.data = memory.readByte(address)
        loadA(state.data)
        state.cycle = 0
    }
    
    private func ldaPageBoundary() {
        state.data = memory.readByte(address)
        if state.pageBoundaryCrossed {
            state.addressHigh = state.addressHigh &+ 1
        } else {
            loadA(state.data)
            state.cycle = 0
        }
    }
    
    //MARK: LDX
    
    private func ldxImmediate() {
        loadX(memory.readByte(state.pc++))
        state.cycle = 0
    }
    
    private func ldxZeroPage() {
        state.data = memory.readByte(UInt16(state.addressLow))
        loadX(state.data)
        state.cycle = 0
    }
    
    private func ldxAbsolute() {
        state.data = memory.readByte(address)
        loadX(state.data)
        state.cycle = 0
    }
    
    private func ldxPageBoundary() {
        state.data = memory.readByte(address)
        if state.pageBoundaryCrossed {
            state.addressHigh = state.addressHigh &+ 1
        } else {
            loadX(state.data)
            state.cycle = 0
        }
    }
    
    //MARK: LDY
    
    private func ldyImmediate() {
        loadY(memory.readByte(state.pc++))
        state.cycle = 0
    }
    
    private func ldyZeroPage() {
        state.data = memory.readByte(UInt16(state.addressLow))
        loadY(state.data)
        state.cycle = 0
    }
    
    private func ldyAbsolute() {
        state.data = memory.readByte(address)
        loadY(state.data)
        state.cycle = 0
    }
    
    private func ldyPageBoundary() {
        state.data = memory.readByte(address)
        if state.pageBoundaryCrossed {
            state.addressHigh = state.addressHigh &+ 1
        } else {
            loadY(state.data)
            state.cycle = 0
        }
    }
    
    //MARK: LSR
    
    private func lsrAccumulator() {
        memory.readByte(state.pc)
        state.c = ((state.a & 1) != 0)
        loadA(state.a >> 1)
        state.cycle = 0
    }

    private func lsrZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.c = ((state.data & 1) != 0)
        state.data = state.data >> 1
    }
    
    //MARK: NOP
    
    private func nop() {
        memory.readByte(state.pc)
        state.cycle = 0
    }
    
    private func nopZeroPage() {
        state.data = memory.readByte(UInt16(state.addressLow))
        state.cycle = 0
    }
    
    private func nopImmediate() {
        state.data = memory.readByte(state.pc++)
        state.cycle = 0
    }
    
    //MARK: ORA
    
    private func oraImmediate() {
        state.data = memory.readByte(state.pc++)
        loadA(state.a | state.data)
        state.cycle = 0
    }
    
    private func oraZeroPage() {
        state.data = memory.readByte(UInt16(state.addressLow))
        loadA(state.a | state.data)
        state.cycle = 0
    }
    
    private func oraPageBoundary() {
        state.data = memory.readByte(address)
        if state.pageBoundaryCrossed {
            state.addressHigh = state.addressHigh &+ 1
        } else {
            loadA(state.a | state.data)
            state.cycle = 0
        }
    }

    private func oraAbsolute() {
        state.data = memory.readByte(address)
        loadA(state.a | state.data)
        state.cycle = 0
    }
    
    //MARK: PHA
    
    private func phaImplied() {
        memory.writeByte(0x100 &+ state.sp, byte: state.a)
        state.sp = state.sp &- 1
        state.cycle = 0
    }
    
    //MARK: PHP
    
    private func phpImplied() {
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

    private func plaImplied() {
        loadA(memory.readByte(0x100 &+ state.sp))
        state.cycle = 0
    }
    
    //MARK: PLP

    private func plpImplied() {
        let p =  memory.readByte(0x100 &+ state.sp)
        state.c = ((p & 0x01) != 0)
        state.z = ((p & 0x02) != 0)
        state.i = ((p & 0x04) != 0)
        state.d = ((p & 0x08) != 0)
        state.v = ((p & 0x40) != 0)
        state.n = ((p & 0x80) != 0)
        state.cycle = 0
    }
    
    //MARK: ROL
    
    private func rolAccumulator() {
        memory.readByte(state.pc)
        let hasCarry = state.c
        state.c = ((state.a & 0x80) != 0)
        loadA((state.a << 1) + (hasCarry ? 1 : 0))
        state.cycle = 0
    }
    
    private func rolZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        let hasCarry = state.c
        state.c = ((state.data & 0x80) != 0)
        state.data = (state.data << 1) + (hasCarry ? 1 : 0)
    }
    
    private func rolAbsolute() {
        memory.writeByte(address, byte: state.data)
        let hasCarry = state.c
        state.c = ((state.data & 0x80) != 0)
        state.data = (state.data << 1) + (hasCarry ? 1 : 0)
    }
    
    //MARK: ROR
    
    private func rorAccumulator() {
        memory.readByte(state.pc)
        let hasCarry = state.c
        state.c = ((state.a & 1) != 0)
        loadA((state.a >> 1) + (hasCarry ? 0x80 : 0))
        state.cycle = 0
    }

    private func rorZeroPage() {
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        let hasCarry = state.c
        state.c = ((state.data & 1) != 0)
        state.data = (state.data >> 1) + (hasCarry ? 0x80 : 0)
    }
    
    private func rorAbsolute() {
        memory.writeByte(address, byte: state.data)
        let hasCarry = state.c
        state.c = ((state.data & 1) != 0)
        state.data = (state.data >> 1) + (hasCarry ? 0x80 : 0)
    }
    
    //MARK: RTI
    
    private func rtiImplied() {
        let p = memory.readByte(0x100 &+ state.sp)
        state.c = (p & 0x01 != 0)
        state.z = (p & 0x02 != 0)
        state.i = (p & 0x04 != 0)
        state.d = (p & 0x08 != 0)
        state.v = (p & 0x40 != 0)
        state.n = (p & 0x80 != 0)
        state.sp = state.sp &+ 1
    }
    
    private func rtiImplied2() {
        pcl = memory.readByte(0x100 &+ state.sp)
        state.sp = state.sp &+ 1
    }
    
    private func rtiImplied3() {
        pch = memory.readByte(0x100 &+ state.sp)
        state.cycle = 0
    }
    
    //MARK: RTS

    private func rtsImplied() {
        pcl = memory.readByte(0x100 &+ state.sp)
        state.sp = state.sp &+ 1
    }
    
    private func rtsImplied2() {
        pch = memory.readByte(0x100 &+ state.sp)
    }
    
    private func rtsImplied3() {
        ++state.pc
        state.cycle = 0
    }
    
    //MARK: SBC
    
    private func sbc(value: UInt8) {
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
    
    private func sbcImmediate() {
        state.data = memory.readByte(state.pc++)
        sbc(state.data)
        state.cycle = 0
    }

    private func sbcZeroPage() {
        state.data = memory.readByte(UInt16(state.addressLow))
        sbc(state.data)
        state.cycle = 0
    }
    
    private func sbcAbsolute() {
        state.data = memory.readByte(address)
        if state.pageBoundaryCrossed {
            state.addressHigh = state.addressHigh &+ 1
        } else {
            sbc(state.data)
            state.cycle = 0
        }
    }
    
    private func sbcAbsolute2() {
        state.data = memory.readByte(address)
        sbc(state.data)
        state.cycle = 0
    }
    
    //MARK: SEC
    
    private func secImplied() {
        memory.readByte(state.pc)
        state.c = true
        state.cycle = 0
    }
    
    //MARK: SED
    
    private func sedImplied() {
        memory.readByte(state.pc)
        state.d = true
        state.cycle = 0
    }
    
    //MARK: SEI
    
    private func seiImplied() {
        memory.readByte(state.pc)
        state.i = true
        state.cycle = 0
    }
    
    //MARK: STA
    
    private func staZeroPage() {
        state.data = state.a
        memory.writeByte(UInt16(state.addressLow), byte: state.a)
        state.cycle = 0
    }

    private func staAbsolute() {
        state.data = state.a
        memory.writeByte(address, byte: state.data)
        state.cycle = 0
    }
    
    //MARK: STX

    private func stxZeroPage() {
        state.data = state.x
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.cycle = 0
    }
    
    private func stxAbsolute() {
        state.data = state.x
        memory.writeByte(address, byte: state.data)
        state.cycle = 0
    }
    
    //MARK: STY
    
    private func styZeroPage() {
        state.data = state.y
        memory.writeByte(UInt16(state.addressLow), byte: state.data)
        state.cycle = 0
    }
    
    private func styAbsolute() {
        state.data = state.y
        memory.writeByte(address, byte: state.data)
        state.cycle = 0
    }
    
    //MARK: TAX
    
    private func taxImplied() {
        memory.readByte(state.pc)
        loadX(state.a)
        state.cycle = 0
    }
    
    //MARK: TAY
    
    private func tayImplied() {
        memory.readByte(state.pc)
        loadY(state.a)
        state.cycle = 0
    }
    
    //MARK: TSX
    
    private func tsxImplied() {
        memory.readByte(state.pc)
        loadX(state.sp)
        state.cycle = 0
    }
    
    //MARK: TXA
    
    private func txaImplied() {
        memory.readByte(state.pc)
        loadA(state.x)
        state.cycle = 0
    }
    
    //MARK: TXS
    
    private func txsImplied() {
        memory.readByte(state.pc)
        state.sp = state.x
        state.cycle = 0
    }
    
    //MARK: TYA
    
    private func tyaImplied() {
        memory.readByte(state.pc)
        loadA(state.y)
        state.cycle = 0
    }
    
}
