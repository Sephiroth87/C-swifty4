//
//  CPU.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 30/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

import Foundation

final internal class CPU {
    
    internal weak var memory: Memory!
    internal var crashHandler: C64CrashHandler?
    
    internal var pc: UInt16
    internal var isAtFetch = false
    private var pcl: UInt8 {
        set {
            pc = (pc & 0xFF00) | UInt16(newValue)
        }
        get {
            return UInt8(truncatingBitPattern: pc)
        }
    }
    private var pch: UInt8 {
        set {
            pc = (pc & 0x00FF) | UInt16(newValue) << 8
        }
        get {
            return UInt8(truncatingBitPattern: pc >> 8)
        }
    }
    
    private var a: UInt8 = 0
    private var x: UInt8 = 0
    private var y: UInt8 = 0
    private var sp: UInt8 = 0
    private var c: Bool = false
    private var z: Bool = false
    private var i: Bool = false
    private var d: Bool = false
    private var b: Bool = true
    private var v: Bool = false
    private var n: Bool = false
    
    internal var portDirection: UInt8 = 0x2F
    private var _port: UInt8 = 0x37
    internal var port: UInt8 {
        set {
            _port = newValue | ~portDirection
        }
        get {
            return _port
        }
    }
    
    private var irqTriggered = false
    private var currentOpcode: UInt16 = 0
    private var cycle = 0
    
    private var data: UInt8 = 0
    private var addressLow: UInt8 = 0
    private var addressHigh: UInt8 = 0
    private var address: UInt16 {
        get {
            return UInt16(addressHigh) << 8 | UInt16(addressLow)
        }
    }
    private var pointer: UInt8 = 0
    private var pageBoundaryCrossed = false
    
    internal init(pc: UInt16) {
        self.pc = pc
    }
    
    internal func executeInstruction() {
        if cycle++ == 0 {
            fetch()
            return
        }
        isAtFetch = false
        switch currentOpcode {
            // ADC
        case 0x69:
            adcImmediate()
        case 0x65:
            cycle == 2 ? zeroPage() : adcZeroPage()
        case 0x6D:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : adcAbsolute()
        case 0x7D:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteX() :
                cycle == 4 ? adcPageBoundary() : adcAbsolute()
        case 0x79:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteY() :
                cycle == 4 ? adcPageBoundary() : adcAbsolute()
        case 0x71:
            cycle == 2 ? indirectIndex() :
                cycle == 3 ? indirectIndex2() :
                cycle == 4 ? indirectY() :
                cycle == 5 ? adcPageBoundary() : adcAbsolute()
            // AND
        case 0x29:
            andImmediate()
        case 0x25:
            cycle == 2 ? zeroPage() : andZeroPage()
        case 0x2D:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : andAbsolute()
        case 0x3D:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteX() :
                cycle == 4 ? andPageBoundary() : andAbsolute()
            // ASL
        case 0x0A:
            aslAccumulator()
        case 0x06:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPage2() :
                cycle == 4 ? aslZeroPage() : zeroPageWriteUpdateNZ()
        case 0x16:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPageX() :
                cycle == 4 ? zeroPage2() :
                cycle == 5 ? aslZeroPage() : zeroPageWriteUpdateNZ()
            // BCC
        case 0x90:
            cycle == 2 ? bccRelative() :
                cycle == 3 ? branch() : branchOverflow()
            // BCS
        case 0xB0:
            cycle == 2 ? bcsRelative() :
                cycle == 3 ? branch() : branchOverflow()
            // BEQ
        case 0xF0:
            cycle == 2 ? beqRelative() :
                cycle == 3 ? branch() : branchOverflow()
            // BIT
        case 0x24:
            cycle == 2 ? zeroPage() : bitZeroPage()
        case 0x2C:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : bitAbsolute()
            // BMI
        case 0x30:
            cycle == 2 ? bmiRelative() :
                cycle == 3 ? branch() : branchOverflow()
            // BNE 
        case 0xD0:
            cycle == 2 ? bneRelative() :
                cycle == 3 ? branch() : branchOverflow()
            // BPL
        case 0x10:
            cycle == 2 ? bplRelative() :
                cycle == 3 ? branch() : branchOverflow()
            // BVC
        case 0x50:
            cycle == 2 ? bvcRelative() :
                cycle == 3 ? branch() : branchOverflow()
            // BVS
        case 0x70:
            cycle == 2 ? bvsRelative() :
                cycle == 3 ? branch() : branchOverflow()
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
            cycle == 2 ? zeroPage() : cmpZeroPage()
        case 0xD5:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPageX() : cmpZeroPage()
        case 0xCD:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : cmpAbsolute()
        case 0xDD:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteX() :
                cycle == 4 ? cmpPageBoundary() : cmpAbsolute()
        case 0xD9:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteY() :
                cycle == 4 ? cmpPageBoundary() : cmpAbsolute()
        case 0xC1:
            cycle == 2 ? indirectIndex() :
                cycle == 3 ? indirectX() :
                cycle == 4 ? indirectIndex2() :
                cycle == 5 ? indirectX2() : cmpAbsolute()
        case 0xD1:
            cycle == 2 ? indirectIndex() :
                cycle == 3 ? indirectIndex2() :
                cycle == 4 ? indirectY() :
                cycle == 5 ? cmpPageBoundary() : cmpAbsolute()
            // CPX
        case 0xE0:
            cpxImmediate()
        case 0xE4:
            cycle == 2 ? zeroPage() : cpxZeroPage()
        case 0xEC:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : cpxAbsolute()
            // CPY
        case 0xC0:
            cpyImmediate()
        case 0xC4:
            cycle == 2 ? zeroPage() : cpyZeroPage()
        case 0xCC:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : cpyAbsolute()
            // DEC
        case 0xC6:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPage2() :
                cycle == 4 ? decZeroPage() : zeroPageWriteUpdateNZ()
        case 0xCE:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() :
                cycle == 4 ? absolute3() :
                cycle == 5 ? decAbsolute() : absoluteWriteUpdateNZ()
        case 0xDE:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteX() :
                cycle == 4 ? absoluteFixPage() :
                cycle == 5 ? absolute3() :
                cycle == 6 ? decAbsolute() : absoluteWriteUpdateNZ()
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
            cycle == 2 ? zeroPage() : eorZeroPage()
        case 0x4D:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : eorAbsolute()
        case 0x5D:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteX() :
                cycle == 4 ? eorPageBoundary() : eorAbsolute()
        case 0x51:
            cycle == 2 ? indirectIndex() :
                cycle == 3 ? indirectIndex2() :
                cycle == 4 ? indirectY() :
                cycle == 5 ? eorPageBoundary() : eorAbsolute()
            // INC
        case 0xE6:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPage2() :
                cycle == 4 ? incZeroPage() : zeroPageWriteUpdateNZ()
        case 0xF6:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPageX() :
                cycle == 4 ? zeroPage2() :
                cycle == 5 ? incZeroPage() : zeroPageWriteUpdateNZ()
        case 0xEE:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() :
                cycle == 4 ? absolute3() :
                cycle == 5 ? incAbsolute() : absoluteWriteUpdateNZ()
        case 0xFE:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteX() :
                cycle == 4 ? absoluteFixPage() :
                cycle == 5 ? absolute3() :
                cycle == 6 ? incAbsolute() : absoluteWriteUpdateNZ()
            // INX
        case 0xE8:
            inxImplied()
            // INY
        case 0xC8:
            inyImplied()
            // JMP
        case 0x4C:
            cycle == 2 ? absolute() : jmpAbsolute()
        case 0x6C:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() :
                cycle == 4 ? indirect() : jmpIndirect()
            // JSR
        case 0x20:
            cycle == 2 ? absolute() :
                cycle == 3 ? {}() :
                cycle == 4 ? pushPch() :
                cycle == 5 ? pushPcl() : jsrAbsolute()
            // LAX
        case 0xAF:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : laxAbsolute()
            // LDA
        case 0xA9:
            ldaImmediate()
        case 0xA5:
            cycle == 2 ? zeroPage() : ldaZeroPage()
        case 0xB5:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPageX() : ldaZeroPage()
        case 0xAD:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : ldaAbsolute()
        case 0xBD:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteX() :
                cycle == 4 ? ldaPageBoundary() : ldaAbsolute()
        case 0xB9:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteY() :
                cycle == 4 ? ldaPageBoundary() : ldaAbsolute()
        case 0xA1:
            cycle == 2 ? indirectIndex() :
                cycle == 3 ? indirectX() :
                cycle == 4 ? indirectIndex2() :
                cycle == 5 ? indirectX2() : ldaAbsolute()
        case 0xB1:
            cycle == 2 ? indirectIndex() :
                cycle == 3 ? indirectIndex2() :
                cycle == 4 ? indirectY() :
                cycle == 5 ? ldaPageBoundary() : ldaAbsolute()
            // LDX
        case 0xA2:
            ldxImmediate()
        case 0xA6:
            cycle == 2 ? zeroPage() : ldxZeroPage()
        case 0xB6:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPageY() : ldxZeroPage()
        case 0xAE:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : ldxAbsolute()
        case 0xBE:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteY() :
                cycle == 4 ? ldxPageBoundary() : ldxAbsolute()
            // LDY
        case 0xA0:
            ldyImmediate()
        case 0xA4:
            cycle == 2 ? zeroPage() : ldyZeroPage()
        case 0xB4:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPageX() : ldyZeroPage()
        case 0xAC:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : ldyAbsolute()
        case 0xBC:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteX() :
                cycle == 4 ? ldyPageBoundary() : ldyAbsolute()
            // LSR
        case 0x4A:
            lsrAccumulator()
        case 0x46:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPage2() :
                cycle == 4 ? lsrZeroPage() : zeroPageWriteUpdateNZ()
        case 0x56:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPageX() :
                cycle == 4 ? zeroPage2() :
                cycle == 5 ? lsrZeroPage() : zeroPageWriteUpdateNZ()
            // NOP
        case 0xEA, 0x5A, 0x7A:
            nop()
        case 0x44:
            cycle == 2 ? zeroPage() : nopZeroPage()
        case 0x14:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPageX() : nopZeroPage()
        case 0x82, 0xE2:
            nopImmediate()
            // ORA
        case 0x09:
            oraImmediate()
        case 0x05:
            cycle == 2 ? zeroPage() : oraZeroPage()
        case 0x0D:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : oraAbsolute()
            // PHA
        case 0x48:
            cycle == 2 ? implied() : phaImplied()
            // PHP
        case 0x08:
            cycle == 2 ? implied() : phpImplied()
            // PLA
        case 0x68:
            cycle == 2 ? implied() :
                cycle == 3 ? implied2() : plaImplied()
            // PLP
        case 0x28:
            cycle == 2 ? implied() :
                cycle == 3 ? implied2() : plpImplied()
            // ROL
        case 0x2A:
            rolAccumulator()
        case 0x26:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPage2() :
                cycle == 4 ? rolZeroPage() : zeroPageWriteUpdateNZ()
        case 0x2E:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() :
                cycle == 4 ? absolute3() :
                cycle == 5 ? rolAbsolute() : absoluteWriteUpdateNZ()
            // ROR
        case 0x6A:
            rorAccumulator()
        case 0x66:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPage2() :
                cycle == 4 ? rorZeroPage() : zeroPageWriteUpdateNZ()
        case 0x76:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPageX() :
                cycle == 4 ? zeroPage2() :
                cycle == 5 ? rorZeroPage() : zeroPageWriteUpdateNZ()
        case 0x6E:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() :
                cycle == 4 ? absolute3() :
                cycle == 5 ? rorAbsolute() : absoluteWriteUpdateNZ()
            // RTI
        case 0x40:
            cycle == 2 ? implied() :
                cycle == 3 ? implied2() :
                cycle == 4 ? rtiImplied() :
                cycle == 5 ? rtiImplied2() : rtiImplied3()
            // RTS
        case 0x60:
            cycle == 2 ? implied() :
                cycle == 3 ? implied2() :
                cycle == 4 ? rtsImplied() :
                cycle == 5 ? rtsImplied2() : rtsImplied3()
            // SBC
        case 0xE9:
            sbcImmediate()
        case 0xE5:
            cycle == 2 ? zeroPage() : sbcZeroPage()
        case 0xF5:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPageX() : sbcZeroPage()
        case 0xED:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() :
                cycle == 4 ? sbcAbsolute() : sbcAbsolute2()
        case 0xFD:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteX() :
                cycle == 4 ? sbcAbsolute() : sbcAbsolute2()
        case 0xF9:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteY() :
                cycle == 4 ? sbcAbsolute() : sbcAbsolute2()
        case 0xF1:
            cycle == 2 ? indirectIndex() :
                cycle == 3 ? indirectIndex2() :
                cycle == 4 ? indirectY() :
                cycle == 5 ? sbcAbsolute() : sbcAbsolute2()
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
            cycle == 2 ? zeroPage() : staZeroPage()
        case 0x95:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPageX() : staZeroPage()
        case 0x8D:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : staAbsolute()
        case 0x9D:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteX() :
                cycle == 4 ? absoluteFixPage() : staAbsolute()
        case 0x99:
            cycle == 2 ? absolute() :
                cycle == 3 ? absoluteY() :
                cycle == 4 ? absoluteFixPage() : staAbsolute()
        case 0x81:
            cycle == 2 ? indirectIndex() :
                cycle == 3 ? indirectX() :
                cycle == 4 ? indirectIndex2() :
                cycle == 5 ? indirectX2() : staAbsolute()
        case 0x91:
            cycle == 2 ? indirectIndex() :
                cycle == 3 ? indirectIndex2() :
                cycle == 4 ? indirectY() :
                cycle == 5 ? absoluteFixPage() : staAbsolute()
            // STX
        case 0x86:
            cycle == 2 ? zeroPage() : stxZeroPage()
        case 0x8E:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : stxAbsolute()
            // STY
        case 0x84:
            cycle == 2 ? zeroPage() : styZeroPage()
        case 0x94:
            cycle == 2 ? zeroPage() :
                cycle == 3 ? zeroPageX() : styZeroPage()
        case 0x8C:
            cycle == 2 ? absolute() :
                cycle == 3 ? absolute2() : styAbsolute()
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
        case 0xFFFF:
            cycle == 2 ? implied() :
                cycle == 3 ? pushPch() :
                cycle == 4 ? pushPcl() :
                cycle == 5 ? irq() :
                cycle == 6 ? irq2() : irq3()
        default:
            let opcodeString = String(currentOpcode, radix: 16, uppercase: true)
            let pcString = String((pc &- UInt16(1)), radix: 16, uppercase: true)
            crashHandler?("Unknown opcode: " + opcodeString + " pc: " + pcString)
        }
    }
    
    internal func setIRQLine() {
        irqTriggered = true
    }
    
    internal func debugInfo() -> [String: String] {
        let description: String = {
            switch self.currentOpcode {
            case 0x69: return String(format: "ADC #%02x", self.memory.readByte(self.pc))
            case 0x65: return String(format: "ADC %02x", self.memory.readByte(self.pc))
            case 0x6D: return String(format: "ADC %04x", self.memory.readWord(self.pc))
            case 0x7D: return String(format: "ADC %04x,X", self.memory.readWord(self.pc))
            case 0x79: return String(format: "ADC %04x,Y", self.memory.readWord(self.pc))
            case 0x71: return String(format: "ADC (%02x),Y", self.memory.readByte(self.pc))
            case 0x29: return String(format: "AND #%02x", self.memory.readByte(self.pc))
            case 0x25: return String(format: "AND %02x", self.memory.readByte(self.pc))
            case 0x2D: return String(format: "AND %04x", self.memory.readWord(self.pc))
            case 0x3D: return String(format: "AND %04x,X", self.memory.readWord(self.pc))
            case 0x0A: return "ASL"
            case 0x06: return String(format: "ASL %02x", self.memory.readByte(self.pc))
            case 0x16: return String(format: "ASL %02x,X", self.memory.readByte(self.pc))
            case 0x90: return String(format: "BCC %02x", self.memory.readByte(self.pc))
            case 0xB0: return String(format: "BCS %02x", self.memory.readByte(self.pc))
            case 0xF0: return String(format: "BEQ %02x", self.memory.readByte(self.pc))
            case 0x24: return String(format: "BIT %02x", self.memory.readByte(self.pc))
            case 0x2C: return String(format: "BIT %04x", self.memory.readWord(self.pc))
            case 0x30: return String(format: "BMI %02x", self.memory.readByte(self.pc))
            case 0xD0: return String(format: "BNE %02x", self.memory.readByte(self.pc))
            case 0x10: return String(format: "BPL %02x", self.memory.readByte(self.pc))
            case 0x50: return String(format: "BVC %02x", self.memory.readByte(self.pc))
            case 0x70: return String(format: "BVS %02x", self.memory.readByte(self.pc))
            case 0x18: return "CLC"
            case 0xD8: return "CLD"
            case 0x58: return "CLI"
            case 0xB8: return "CLV"
            case 0xC9: return String(format: "CMP #%02x", self.memory.readByte(self.pc))
            case 0xC5: return String(format: "CMP %02x", self.memory.readByte(self.pc))
            case 0xD5: return String(format: "CMP %02x,X", self.memory.readByte(self.pc))
            case 0xCD: return String(format: "CMP %04x", self.memory.readWord(self.pc))
            case 0xDD: return String(format: "CMP %04x,X", self.memory.readWord(self.pc))
            case 0xD9: return String(format: "CMP %04x,Y", self.memory.readWord(self.pc))
            case 0xC1: return String(format: "CMP (%02x,X)", self.memory.readByte(self.pc))
            case 0xD1: return String(format: "CMP (%02x),Y", self.memory.readByte(self.pc))
            case 0xE0: return String(format: "CPX #%02x", self.memory.readByte(self.pc))
            case 0xE4: return String(format: "CPX %02x", self.memory.readByte(self.pc))
            case 0xEC: return String(format: "CPX %04x", self.memory.readWord(self.pc))
            case 0xC0: return String(format: "CPY #%02x", self.memory.readByte(self.pc))
            case 0xC4: return String(format: "CPY %02x", self.memory.readByte(self.pc))
            case 0xCC: return String(format: "CPY %04x", self.memory.readWord(self.pc))
            case 0xC6: return String(format: "DEC %02x", self.memory.readByte(self.pc))
            case 0xCE: return String(format: "DEC %04x", self.memory.readWord(self.pc))
            case 0xDE: return String(format: "DEC %04x,X", self.memory.readWord(self.pc))
            case 0xCA: return "DEX"
            case 0x88: return "DEY"
            case 0x49: return String(format: "EOR #%02x", self.memory.readByte(self.pc))
            case 0x45: return String(format: "EOR %02x", self.memory.readByte(self.pc))
            case 0x4D: return String(format: "EOR %04x", self.memory.readWord(self.pc))
            case 0x5D: return String(format: "EOR %04x,X", self.memory.readWord(self.pc))
            case 0x51: return String(format: "EOR (%02x),Y", self.memory.readByte(self.pc))
            case 0xE6: return String(format: "INC %02x", self.memory.readByte(self.pc))
            case 0xF6: return String(format: "INC %02x,X", self.memory.readByte(self.pc))
            case 0xEE: return String(format: "INC %04x", self.memory.readWord(self.pc))
            case 0xFE: return String(format: "INC %04x,X", self.memory.readWord(self.pc))
            case 0xE8: return "INX"
            case 0xC8: return "INY"
            case 0x4C: return String(format: "JMP %04x", self.memory.readWord(self.pc))
            case 0x6C: return String(format: "JMP (%04x)", self.memory.readWord(self.pc))
            case 0x20: return String(format: "JSR %04x", self.memory.readWord(self.pc))
            case 0xAF: return String(format: "LAX* %04x", self.memory.readWord(self.pc))
            case 0xA9: return String(format: "LDA #%02x", self.memory.readByte(self.pc))
            case 0xA5: return String(format: "LDA %02x", self.memory.readByte(self.pc))
            case 0xB5: return String(format: "LDA %02x,X", self.memory.readByte(self.pc))
            case 0xAD: return String(format: "LDA %04x", self.memory.readWord(self.pc))
            case 0xBD: return String(format: "LDA %04x,X", self.memory.readWord(self.pc))
            case 0xB9: return String(format: "LDA %04x,Y", self.memory.readWord(self.pc))
            case 0xA1: return String(format: "LDA (%02x,X)", self.memory.readByte(self.pc))
            case 0xB1: return String(format: "LDA (%02x),Y", self.memory.readByte(self.pc))
            case 0xA2: return String(format: "LDX #%02x", self.memory.readByte(self.pc))
            case 0xA6: return String(format: "LDX %02x", self.memory.readByte(self.pc))
            case 0xB6: return String(format: "LDX %02x,Y", self.memory.readByte(self.pc))
            case 0xAE: return String(format: "LDX %04x", self.memory.readWord(self.pc))
            case 0xBE: return String(format: "LDX %04x,Y", self.memory.readWord(self.pc))
            case 0xA0: return String(format: "LDY #%02x", self.memory.readByte(self.pc))
            case 0xA4: return String(format: "LDY %02x", self.memory.readByte(self.pc))
            case 0xB4: return String(format: "LDY %02x,X", self.memory.readByte(self.pc))
            case 0xAC: return String(format: "LDY %04x", self.memory.readWord(self.pc))
            case 0xBC: return String(format: "LDY %04x,X", self.memory.readWord(self.pc))
            case 0x4A: return "LSR"
            case 0x46: return String(format: "LSR %02x", self.memory.readByte(self.pc))
            case 0x56: return String(format: "LSR %02x,X", self.memory.readByte(self.pc))
            case 0xEA: return "NOP"
            case 0x5A: return "NOP*"
            case 0x7A: return "NOP*"
            case 0x44: return String(format: "NOP* %02x", self.memory.readByte(self.pc))
            case 0x14: return String(format: "NOP* %02x,X", self.memory.readByte(self.pc))
            case 0x82: return String(format: "NOP* #%02x", self.memory.readByte(self.pc))
            case 0xE2: return String(format: "NOP* #%02x", self.memory.readByte(self.pc))
            case 0x09: return String(format: "ORA #%02x", self.memory.readByte(self.pc))
            case 0x05: return String(format: "ORA %02x", self.memory.readByte(self.pc))
            case 0x0D: return String(format: "ORA %04x", self.memory.readWord(self.pc))
            case 0x48: return "PHA"
            case 0x08: return "PHP"
            case 0x68: return "PLA"
            case 0x28: return "PLP"
            case 0x2A: return "ROL"
            case 0x26: return String(format: "ROL %02x", self.memory.readByte(self.pc))
            case 0x2E: return String(format: "ROL %04x", self.memory.readWord(self.pc))
            case 0x6A: return "ROR"
            case 0x66: return String(format: "ROR %02x", self.memory.readByte(self.pc))
            case 0x76: return String(format: "ROR %02x,X", self.memory.readByte(self.pc))
            case 0x6E: return String(format: "ROR %04x", self.memory.readWord(self.pc))
            case 0x40: return "RTI"
            case 0x60: return "RTS"
            case 0xE9: return String(format: "SBC #%02x", self.memory.readByte(self.pc))
            case 0xE5: return String(format: "SBC %02x", self.memory.readByte(self.pc))
            case 0xF5: return String(format: "SBC %02x,X", self.memory.readByte(self.pc))
            case 0xED: return String(format: "SBC %04x", self.memory.readWord(self.pc))
            case 0xFD: return String(format: "SBC %04x,X", self.memory.readWord(self.pc))
            case 0xF9: return String(format: "SBC %04x,Y", self.memory.readWord(self.pc))
            case 0xF1: return String(format: "SBC (%02x),Y", self.memory.readByte(self.pc))
            case 0x38: return "SEC"
            case 0xF8: return "SED"
            case 0x78: return "SEI"
            case 0x85: return String(format: "STA %02x", self.memory.readByte(self.pc))
            case 0x95: return String(format: "STA %02x,X", self.memory.readByte(self.pc))
            case 0x8D: return String(format: "STA %04x", self.memory.readWord(self.pc))
            case 0x9D: return String(format: "STA %04x,X", self.memory.readWord(self.pc))
            case 0x99: return String(format: "STA %04x,Y", self.memory.readWord(self.pc))
            case 0x81: return String(format: "STA (%02x,X)", self.memory.readByte(self.pc))
            case 0x91: return String(format: "STA (%02x),Y", self.memory.readByte(self.pc))
            case 0x86: return String(format: "STX %02x", self.memory.readByte(self.pc))
            case 0x8E: return String(format: "STX %04x", self.memory.readWord(self.pc))
            case 0x84: return String(format: "STY %02x", self.memory.readByte(self.pc))
            case 0x94: return String(format: "STY %02x,X", self.memory.readByte(self.pc))
            case 0x8C: return String(format: "STY %04x", self.memory.readWord(self.pc))
            case 0xAA: return "TAX"
            case 0xA8: return "TAY"
            case 0xBA: return "TSX"
            case 0x8A: return "TXA"
            case 0x9a: return "TXS"
            case 0x98: return "TYA"
            default: return String(format: "Unknown opcode: %02x", self.currentOpcode)
            }
            }()
        return ["pc": String(format: "%04x", pc &- UInt16(1)),
            "a": String(format: "%02x", a),
            "x": String(format: "%02x", x),
            "y": String(format: "%02x", y),
            "sp": String(format: "%02x", sp),
            "sr.n": n ? "✓" : " ",
            "sr.v": v ? "✓" : " ",
            "sr.b": b ? "✓" : " ",
            "sr.d": d ? "✓" : " ",
            "sr.i": i ? "✓" : " ",
            "sr.z": z ? "✓" : " ",
            "sr.c": c ? "✓" : " ",
            "description": description
        ]
    }
    
    //MARK: Helpers
    
    private func updateNFlag(value: UInt8) {
        n = (value & 0x80 != 0)
    }
    
    private func updateZFlag(value: UInt8) {
        z = (value == 0)
    }
    
    private func loadA(value: UInt8) {
        a = value
        z = (value == 0)
        n = (value & 0x80 != 0)
    }
    
    private func loadX(value: UInt8) {
        x = value
        z = (value == 0)
        n = (value & 0x80 != 0)
    }
    
    private func loadY(value: UInt8) {
        y = value
        z = (value == 0)
        n = (value & 0x80 != 0)
    }
    
    private func fetch() {
        if irqTriggered && !i {
            irqTriggered = false
            currentOpcode = 0xFFFF
            return
        }
        isAtFetch = true
        currentOpcode = UInt16(memory.readByte(pc))
        pc = pc &+ UInt16(1)
    }
    
    private func pushPch() {
        memory.writeByte(0x100 &+ sp, byte: pch)
        sp = sp &- 1
    }
    
    private func pushPcl() {
        memory.writeByte(0x100 &+ sp, byte: pcl)
        sp = sp &- 1
    }
    
    //MARK: IRQ

    private func irq() {
        let p = UInt8((c ? 0x01 : 0) |
            (z ? 0x02 : 0) |
            (i ? 0x04 : 0) |
            (d ? 0x08 : 0) |
            //                (b ? 0x10 : 0) | b is 0 on IRQ
            0x20 |
            (v ? 0x40 : 0) |
            (n ? 0x80 : 0))
        memory.writeByte(0x100 &+ sp, byte: p)
        sp = sp &- 1
        i = true
    }

    private func irq2() {
        data = memory.readByte(0xFFFE)
    }
    
    private func irq3() {
        pcl = data
        pch = memory.readByte(0xFFFF)
        cycle = 0
    }
    
    //MARK: Opcodes
    
    //MARK: Addressing
    
    private func zeroPage() {
        addressLow = memory.readByte(pc++)
    }
    
    private func zeroPage2() {
        data = memory.readByte(UInt16(addressLow))
    }
    
    private func zeroPageWriteUpdateNZ() {
        memory.writeByte(UInt16(addressLow), byte: data)
        z = (data == 0)
        n = (data & 0x80 != 0)
        cycle = 0
    }
    
    private func zeroPageX() {
        data = memory.readByte(UInt16(addressLow))
        addressLow = addressLow &+ x
    }
    
    private func zeroPageY() {
        data = memory.readByte(UInt16(addressLow))
        addressLow = addressLow &+ y
    }
    
    private func absolute() {
        addressLow = memory.readByte(pc++)
    }
    
    private func absolute2() {
        addressHigh = memory.readByte(pc++)
    }
    
    private func absolute3() {
        data = memory.readByte(address)
    }
    
    private func absoluteWriteUpdateNZ() {
        memory.writeByte(address, byte: data)
        z = (data == 0)
        n = (data & 0x80 != 0)
        cycle = 0
    }
    
    private func absoluteX() {
        addressHigh = memory.readByte(pc++)
        pageBoundaryCrossed = (UInt16(addressLow) &+ x >= 0x100)
        addressLow = addressLow &+ x
    }
    
    private func absoluteY() {
        addressHigh = memory.readByte(pc++)
        pageBoundaryCrossed = (UInt16(addressLow) &+ y >= 0x100)
        addressLow = addressLow &+ y
    }
    
    private func absoluteFixPage() {
        memory.readByte(address)
        if pageBoundaryCrossed {
            addressHigh = addressHigh &+ 1
        }
    }
    
    private func indirect() {
        data = memory.readByte(address)
    }
    
    private func indirectIndex() {
        pointer = memory.readByte(pc++)
    }
    
    private func indirectIndex2() {
        addressLow = memory.readByte(UInt16(pointer++))
    }
    
    private func indirectX() {
        memory.readByte(UInt16(pointer))
        pointer = pointer &+ x
    }
    
    private func indirectX2() {
        addressHigh = memory.readByte(UInt16(pointer++))
    }
    
    private func indirectY() {
        addressHigh = memory.readByte(UInt16(pointer++))
        pageBoundaryCrossed = (UInt16(addressLow) &+ y >= 0x100)
        addressLow = addressLow &+ y
    }
    
    private func implied() {
        memory.readByte(pc)
    }
    
    private func implied2() {
        sp = sp &+ 1
    }
    
    //MARK: ADC
    
    private func adc(value: UInt8) {
        if d {
            var lowNybble = (a & 0x0F) &+ (value & 0x0F) &+ (c ? 1 : 0)
            var highNybble = (a >> 4) &+ (value >> 4)
            if lowNybble > 9 {
                lowNybble = lowNybble &+ 6
            }
            if lowNybble > 0x0F {
                highNybble = highNybble &+ 1
            }
            z = ((a &+ value &+ (c ? 1 : 0)) & 0xFF == 0)
            n = (highNybble & 0x08 != 0)
            v = ((((highNybble << 4) ^ a) & 0x80) != 0 && ((a ^ value) & 0x80) == 0)
            if highNybble > 9 {
                highNybble = highNybble &+ 6
            }
            c = (highNybble > 0x0F)
            a = (highNybble << 4) | (lowNybble & 0x0F)
        } else {
            let tempA = UInt16(a)
            let sum = (tempA + UInt16(value) + (c ? 1 : 0))
            c = (sum > 0xFF)
            v = (((tempA ^ UInt16(value)) & 0x80) == 0 && ((tempA ^ sum) & 0x80) != 0)
            loadA(UInt8(truncatingBitPattern: sum))
        }
    }
    
    private func adcImmediate() {
        data = memory.readByte(pc++)
        adc(data)
        cycle = 0
    }
    
    private func adcZeroPage() {
        data = memory.readByte(UInt16(addressLow))
        adc(data)
        cycle = 0
    }
    
    private func adcPageBoundary() {
        data = memory.readByte(address)
        if pageBoundaryCrossed {
            addressHigh = addressHigh &+ 1
        } else {
            adc(data)
            cycle = 0
        }
    }
    
    private func adcAbsolute() {
        data = memory.readByte(address)
        adc(data)
        cycle = 0
    }
    
    //MARK: AND
    
    private func andImmediate() {
        data = memory.readByte(pc++)
        loadA(a & data)
        cycle = 0
    }
    
    private func andZeroPage() {
        data = memory.readByte(UInt16(addressLow))
        loadA(a & data)
        cycle = 0
    }
    
    private func andPageBoundary() {
        data = memory.readByte(address)
        if pageBoundaryCrossed {
            addressHigh = addressHigh &+ 1
        } else {
            loadA(a & data)
            cycle = 0
        }
    }
    
    private func andAbsolute() {
        data = memory.readByte(address)
        loadA(a & data)
        cycle = 0
    }
    
    //MARK: ASL
    
    private func aslAccumulator() {
        memory.readByte(pc)
        c = ((a & 0x80) != 0)
        loadA(a << 1)
        cycle = 0
    }
    
    private func aslZeroPage() {
        memory.writeByte(UInt16(addressLow), byte: data)
        c = ((data & 0x80) != 0)
        data = data << 1
    }

    //MARK: BCC
    
    private func branch() {
        memory.readByte(pc)
        let oldPch = pch
        pc = pc &+ Int8(bitPattern: data)
        if pch == oldPch {
            //TODO: delay IRQs
            cycle = 0
        }
    }
    
    private func branchOverflow() {
        if data & 0x80 != 0 {
            memory.readByte(self.pc &+ UInt16(0x100))
        } else {
            memory.readByte(self.pc &- UInt16(0x100))
        }
        cycle = 0
    }
    
    private func bccRelative() {
        data = memory.readByte(pc++)
        if c {
            cycle = 0
        }
    }
    
    //MARK: BCS
    
    private func bcsRelative() {
        data = memory.readByte(pc++)
        if !c {
            cycle = 0
        }
    }
    
    //MARK: BEQ
    
    private func beqRelative() {
        data = memory.readByte(pc++)
        if !z {
            cycle = 0
        }
    }
    
    //MARK: BIT

    private func bitZeroPage() {
        data = memory.readByte(UInt16(addressLow))
        n = ((data & 128) != 0)
        v = ((data & 64) != 0)
        z = ((data & a) == 0)
        cycle = 0
    }
    
    private func bitAbsolute() {
        data = memory.readByte(address)
        n = ((data & 128) != 0)
        v = ((data & 64) != 0)
        z = ((data & a) == 0)
        cycle = 0
    }
    
    //MARK: BMI
    
    private func bmiRelative() {
        data = memory.readByte(pc++)
        if !n {
            cycle = 0
        }
    }
    
    //MARK: BNE
    
    private func bneRelative() {
        data = memory.readByte(pc++)
        if z {
            cycle = 0
        }
    }

    //MARK: BPL
    
    private func bplRelative() {
        data = memory.readByte(pc++)
        if n {
            cycle = 0
        }
    }
    
    //MARK: BVC
    
    private func bvcRelative() {
        data = memory.readByte(pc++)
        if v {
            cycle = 0
        }
    }
    
    //MARK: BVS
    
    private func bvsRelative() {
        data = memory.readByte(pc++)
        if !v {
            cycle = 0
        }
    }
    
    //MARK: CLC
    
    private func clcImplied() {
        memory.readByte(pc)
        c = false
        cycle = 0
    }
    
    //MARK: CLD
    
    private func cldImplied() {
        memory.readByte(pc)
        d = false
        cycle = 0
    }
    
    //MARK: CLI
    
    private func cliImplied() {
        memory.readByte(pc)
        i = false
        cycle = 0
    }
    
    //MARK: CLV
    
    private func clvImplied() {
        memory.readByte(pc)
        v = false
        cycle = 0
    }
    
    //MARK: CMP
    
    private func cmp(value1: UInt8, _ value2: UInt8) {
        let diff = value1 &- value2
        z = (diff == 0)
        n = (diff & 0x80 != 0)
        c = (value1 >= value2)
    }
    
    private func cmpImmediate() {
        data = memory.readByte(pc++)
        cmp(a, data)
        cycle = 0
    }
    
    private func cmpZeroPage() {
        data = memory.readByte(UInt16(addressLow))
        cmp(a, data)
        cycle = 0
    }

    private func cmpAbsolute() {
        data = memory.readByte(address)
        cmp(a, data)
        cycle = 0
    }
    
    private func cmpPageBoundary() {
        data = memory.readByte(address)
        if pageBoundaryCrossed {
            addressHigh = addressHigh &+ 1
        } else {
            cmp(a, data)
            cycle = 0
        }
    }
    
    //MARK: CPX
    
    private func cpxImmediate() {
        data = memory.readByte(pc++)
        cmp(x, data)
        cycle = 0
    }

    private func cpxZeroPage() {
        data = memory.readByte(UInt16(addressLow))
        cmp(x, data)
        cycle = 0
    }
    
    private func cpxAbsolute() {
        data = memory.readByte(address)
        cmp(x, data)
        cycle = 0
    }
    
    //MARK: CPY
    
    private func cpyImmediate() {
        data = memory.readByte(pc++)
        cmp(y, data)
        cycle = 0
    }

    private func cpyZeroPage() {
        data = memory.readByte(UInt16(addressLow))
        cmp(y, data)
        cycle = 0
    }
    
    private func cpyAbsolute() {
        data = memory.readByte(address)
        cmp(y, data)
        cycle = 0
    }
    
    //MARK: DEC
    
    private func decZeroPage() {
        memory.writeByte(UInt16(addressLow), byte: data)
        data = data &- 1
    }
    
    private func decAbsolute() {
        memory.writeByte(address, byte: data)
        data = data &- 1
    }
    
    //MARK: DEX
    
    private func dexImplied() {
        loadX(x &- 1)
        cycle = 0
    }
    
    //MARK: DEY
    
    private func deyImplied() {
        loadY(y &- 1)
        cycle = 0
    }
    
    //MARK: EOR
    
    private func eorImmediate() {
        data = memory.readByte(pc++)
        loadA(a ^ data)
        cycle = 0
    }

    private func eorZeroPage() {
        data = memory.readByte(UInt16(addressLow))
        loadA(a ^ data)
        cycle = 0
    }
    
    private func eorAbsolute() {
        data = memory.readByte(address)
        loadA(a ^ data)
        cycle = 0
    }
    
    private func eorPageBoundary() {
        data = memory.readByte(address)
        if pageBoundaryCrossed {
            addressHigh = addressHigh &+ 1
        } else {
            loadA(a ^ data)
            cycle = 0
        }
    }
    
    //MARK: INC

    private func incZeroPage() {
        memory.writeByte(UInt16(addressLow), byte: data)
        data = data &+ 1
    }
    
    private func incAbsolute() {
        memory.writeByte(address, byte: data)
        data = data &+ 1
    }
    
    //MARK: INX
    
    private func inxImplied() {
        memory.readByte(pc)
        loadX(x &+ 1)
        cycle = 0
    }
    
    //MARK: INY
    
    private func inyImplied() {
        memory.readByte(pc)
        loadY(y &+ 1)
        cycle = 0
    }
    
    //MARK: JMP
    
    private func jmpAbsolute() {
        addressHigh = memory.readByte(pc)
        pc = address
        cycle = 0
    }

    private func jmpIndirect() {
        pcl = data
        addressLow = addressLow &+ 1
        pch = memory.readByte(address)
        cycle = 0
    }
    
    //MARK: JSR
    
    private func jsrAbsolute() {
        addressHigh = memory.readByte(pc)
        pc = address
        cycle = 0
    }
    
    //MARK: LAX
    
    private func laxAbsolute() {
        data = memory.readByte(address)
        loadA(data)
        loadX(data)
        cycle = 0
    }
    
    //MARK: LDA
    
    private func ldaImmediate() {
        loadA(memory.readByte(pc++))
        cycle = 0
    }
    
    private func ldaZeroPage() {
        data = memory.readByte(UInt16(addressLow))
        loadA(data)
        cycle = 0
    }

    private func ldaAbsolute() {
        data = memory.readByte(address)
        loadA(data)
        cycle = 0
    }
    
    private func ldaPageBoundary() {
        data = memory.readByte(address)
        if pageBoundaryCrossed {
            addressHigh = addressHigh &+ 1
        } else {
            loadA(data)
            cycle = 0
        }
    }
    
    //MARK: LDX
    
    private func ldxImmediate() {
        loadX(memory.readByte(pc++))
        cycle = 0
    }
    
    private func ldxZeroPage() {
        data = memory.readByte(UInt16(addressLow))
        loadX(data)
        cycle = 0
    }
    
    private func ldxAbsolute() {
        data = memory.readByte(address)
        loadX(data)
        cycle = 0
    }
    
    private func ldxPageBoundary() {
        data = memory.readByte(address)
        if pageBoundaryCrossed {
            addressHigh = addressHigh &+ 1
        } else {
            loadX(data)
            cycle = 0
        }
    }
    
    //MARK: LDY
    
    private func ldyImmediate() {
        loadY(memory.readByte(pc++))
        cycle = 0
    }
    
    private func ldyZeroPage() {
        data = memory.readByte(UInt16(addressLow))
        loadY(data)
        cycle = 0
    }
    
    private func ldyAbsolute() {
        data = memory.readByte(address)
        loadY(data)
        cycle = 0
    }
    
    private func ldyPageBoundary() {
        data = memory.readByte(address)
        if pageBoundaryCrossed {
            addressHigh = addressHigh &+ 1
        } else {
            loadY(data)
            cycle = 0
        }
    }
    
    //MARK: LSR
    
    private func lsrAccumulator() {
        memory.readByte(pc)
        c = ((a & 1) != 0)
        loadA(a >> 1)
        cycle = 0
    }

    private func lsrZeroPage() {
        memory.writeByte(UInt16(addressLow), byte: data)
        c = ((data & 1) != 0)
        data = data >> 1
    }
    
    //MARK: NOP
    
    private func nop() {
        memory.readByte(pc)
        cycle = 0
    }
    
    private func nopZeroPage() {
        data = memory.readByte(UInt16(addressLow))
        cycle = 0
    }
    
    private func nopImmediate() {
        data = memory.readByte(pc++)
        cycle = 0
    }
    
    //MARK: ORA
    
    private func oraImmediate() {
        data = memory.readByte(pc++)
        loadA(a | data)
        cycle = 0
    }
    
    private func oraZeroPage() {
        data = memory.readByte(UInt16(addressLow))
        loadA(a | data)
        cycle = 0
    }

    private func oraAbsolute() {
        data = memory.readByte(address)
        loadA(a | data)
        cycle = 0
    }
    
    //MARK: PHA
    
    private func phaImplied() {
        memory.writeByte(0x100 &+ sp, byte: a)
        sp = sp &- 1
        cycle = 0
    }
    
    //MARK: PHP
    
    private func phpImplied() {
        let p = UInt8((c ? 0x01 : 0) |
            (z ? 0x02 : 0) |
            (i ? 0x04 : 0) |
            (d ? 0x08 : 0) |
            (b ? 0x10 : 0) |
            0x20 |
            (v ? 0x40 : 0) |
            (n ? 0x80 : 0))
        memory.writeByte(0x100 &+ sp, byte: p)
        sp = sp &- 1
        cycle = 0
    }
    
    //MARK: PLA

    private func plaImplied() {
        loadA(memory.readByte(0x100 &+ sp))
        cycle = 0
    }
    
    //MARK: PLP

    private func plpImplied() {
        let p =  memory.readByte(0x100 &+ sp)
        c = ((p & 0x01) != 0)
        z = ((p & 0x02) != 0)
        i = ((p & 0x04) != 0)
        d = ((p & 0x08) != 0)
        v = ((p & 0x40) != 0)
        n = ((p & 0x80) != 0)
        cycle = 0
    }
    
    //MARK: ROL
    
    private func rolAccumulator() {
        memory.readByte(pc)
        let hasCarry = c
        c = ((a & 0x80) != 0)
        loadA((a << 1) + (hasCarry ? 1 : 0))
        cycle = 0
    }
    
    private func rolZeroPage() {
        memory.writeByte(UInt16(addressLow), byte: data)
        let hasCarry = c
        c = ((data & 0x80) != 0)
        data = (data << 1) + (hasCarry ? 1 : 0)
    }
    
    private func rolAbsolute() {
        memory.writeByte(address, byte: data)
        let hasCarry = c
        c = ((data & 0x80) != 0)
        data = (data << 1) + (hasCarry ? 1 : 0)
    }
    
    //MARK: ROR
    
    private func rorAccumulator() {
        memory.readByte(pc)
        let hasCarry = c
        c = ((a & 1) != 0)
        loadA((a >> 1) + (hasCarry ? 0x80 : 0))
        cycle = 0
    }

    private func rorZeroPage() {
        memory.writeByte(UInt16(addressLow), byte: data)
        let hasCarry = c
        c = ((data & 1) != 0)
        data = (data >> 1) + (hasCarry ? 0x80 : 0)
    }
    
    private func rorAbsolute() {
        memory.writeByte(address, byte: data)
        let hasCarry = c
        c = ((data & 1) != 0)
        data = (data >> 1) + (hasCarry ? 0x80 : 0)
    }
    
    //MARK: RTI
    
    private func rtiImplied() {
        let p = memory.readByte(0x100 &+ sp)
        c = (p & 0x01 != 0)
        z = (p & 0x02 != 0)
        i = (p & 0x04 != 0)
        d = (p & 0x08 != 0)
        v = (p & 0x40 != 0)
        n = (p & 0x80 != 0)
        sp = sp &+ 1
    }
    
    private func rtiImplied2() {
        pcl = memory.readByte(0x100 &+ sp)
        sp = sp &+ 1
    }
    
    private func rtiImplied3() {
        pch = memory.readByte(0x100 &+ sp)
        cycle = 0
    }
    
    //MARK: RTS

    private func rtsImplied() {
        pcl = memory.readByte(0x100 &+ sp)
        sp = sp &+ 1
    }
    
    private func rtsImplied2() {
        pch = memory.readByte(0x100 &+ sp)
    }
    
    private func rtsImplied3() {
        ++pc
        cycle = 0
    }
    
    //MARK: SBC
    
    private func sbc(value: UInt8) {
        if d {
            let tempA = UInt16(a)
            let sum = (tempA &- UInt16(value) &- (c ? 0 : 1))
            var lowNybble = (a & 0x0F) &- (value & 0x0F) &- (c ? 0 : 1)
            var highNybble = (a >> 4) &- (value >> 4)
            if lowNybble & 0x10 != 0 {
                lowNybble = lowNybble &- 6
                highNybble = highNybble &- 1
            }
            if highNybble & 0x10 != 0 {
                highNybble = highNybble &- 6
            }
            c = (sum < 0x100)
            v = (((tempA ^ sum) & 0x80) != 0 && ((tempA ^ UInt16(value)) & 0x80) != 0)
            z = (UInt8(truncatingBitPattern: sum) == 0)
            n = (sum & 0x80 != 0)
            a = (highNybble << 4) | (lowNybble & 0x0F)
        } else {
            let tempA = UInt16(a)
            let sum = (tempA &- UInt16(value) &- (c ? 0 : 1))
            c = (sum <= 0xFF)
            v = (((UInt16(a) ^ sum) & 0x80) != 0 && ((UInt16(a) ^ UInt16(value)) & 0x80) != 0)
            loadA(UInt8(truncatingBitPattern: sum))
        }
    }
    
    private func sbcImmediate() {
        data = memory.readByte(pc++)
        sbc(data)
        cycle = 0
    }

    private func sbcZeroPage() {
        data = memory.readByte(UInt16(addressLow))
        sbc(data)
        cycle = 0
    }
    
    private func sbcAbsolute() {
        data = memory.readByte(address)
        if pageBoundaryCrossed {
            addressHigh = addressHigh &+ 1
        } else {
            sbc(data)
            cycle = 0
        }
    }
    
    private func sbcAbsolute2() {
        data = memory.readByte(address)
        sbc(data)
        cycle = 0
    }
    
    //MARK: SEC
    
    private func secImplied() {
        memory.readByte(pc)
        c = true
        cycle = 0
    }
    
    //MARK: SED
    
    private func sedImplied() {
        memory.readByte(pc)
        d = true
        cycle = 0
    }
    
    //MARK: SEI
    
    private func seiImplied() {
        memory.readByte(pc)
        i = true
        cycle = 0
    }
    
    //MARK: STA
    
    private func staZeroPage() {
        data = a
        memory.writeByte(UInt16(addressLow), byte: a)
        cycle = 0
    }

    private func staAbsolute() {
        data = a
        memory.writeByte(address, byte: data)
        cycle = 0
    }
    
    //MARK: STX

    private func stxZeroPage() {
        data = x
        memory.writeByte(UInt16(addressLow), byte: data)
        cycle = 0
    }
    
    private func stxAbsolute() {
        data = x
        memory.writeByte(address, byte: data)
        cycle = 0
    }
    
    //MARK: STY
    
    private func styZeroPage() {
        data = y
        memory.writeByte(UInt16(addressLow), byte: data)
        cycle = 0
    }
    
    private func styAbsolute() {
        data = y
        memory.writeByte(address, byte: data)
        cycle = 0
    }
    
    //MARK: TAX
    
    private func taxImplied() {
        memory.readByte(pc)
        loadX(a)
        cycle = 0
    }
    
    //MARK: TAY
    
    private func tayImplied() {
        memory.readByte(pc)
        loadY(a)
        cycle = 0
    }
    
    //MARK: TSX
    
    private func tsxImplied() {
        memory.readByte(pc)
        loadX(sp)
        cycle = 0
    }
    
    //MARK: TXA
    
    private func txaImplied() {
        memory.readByte(pc)
        loadA(x)
        cycle = 0
    }
    
    //MARK: TXS
    
    private func txsImplied() {
        memory.readByte(pc)
        sp = x
        cycle = 0
    }
    
    //MARK: TYA
    
    private func tyaImplied() {
        memory.readByte(pc)
        loadA(y)
        cycle = 0
    }
    
}
