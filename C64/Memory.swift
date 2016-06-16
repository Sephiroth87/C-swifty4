//
//  Memory.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 05/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

import Foundation

internal protocol Memory: class {
    
    func readByte(position: UInt16) -> UInt8
    func readWord(position: UInt16) -> UInt16
    func writeByte(position: UInt16, byte: UInt8)
    
}

internal struct C64MemoryState: ComponentState {
    
    private var ram: [UInt8] = [UInt8](count: 0x10000, repeatedValue: 0)
    private var colorRam: [UInt8] = [UInt8](count: 1024, repeatedValue: 0)
    
    //MARK: Helpers
    private var characterRomVisible = false
    private var kernalRomVisible = true
    private var basicRomVisible = true
    private var ioVisible = true
    //MARK: -
    
    static func extract(binaryDump: BinaryDump) -> C64MemoryState {
        return C64MemoryState(ram: binaryDump.next(0x10000), colorRam: binaryDump.next(1024), characterRomVisible: binaryDump.next(), kernalRomVisible: binaryDump.next(), basicRomVisible: binaryDump.next(), ioVisible: binaryDump.next())
    }
    
}

final internal class C64Memory: Memory , Component {
    
    internal var state = C64MemoryState()
    
    private var rom: [UInt8] = [UInt8](count: 0x10000, repeatedValue: 0)
    
    internal weak var cpu: CPU!
    internal weak var cia1: CIA1!
    internal weak var cia2: CIA2!
    internal weak var sid: SID!
    internal weak var vic: VIC!
    internal var crashHandler: C64CrashHandler?
    
    init() {
        // RAM powerup pattern
        for i in 0..<512 {
            for j in 0..<64 {
                state.ram[128 * i + 64 + j] = 0xFF
            }
        }
    }
    
    private func writeRomData(data: UnsafePointer<UInt8>, position: Int, size: Int) {
        for i in 0..<size {
            rom[position+i] = data[i]
        }
    }
    
    internal func writeKernalData(data: UnsafePointer<UInt8>) {
        writeRomData(data, position: 0xE000, size: 0x2000)
    }
    
    internal func writeBasicData(data: UnsafePointer<UInt8>) {
        writeRomData(data, position: 0xA000, size: 0x2000)
    }
    
    internal func writeCharacterData(data: UnsafePointer<UInt8>) {
        writeRomData(data, position: 0xD000, size: 0x1000)
    }
    
    internal func writeRamData(data: UnsafePointer<UInt8>, position: Int, size: Int) {
        for i in 0..<size {
            state.ram[position+i] = data[i]
        }
    }
    
    //MARK: Read
    
    internal func readByte(position: UInt16) -> UInt8 {
        switch position {
        case 0x0000, 0x0001:
            return cpu.readByte(UInt8(truncatingBitPattern: position))
        case 0xA000...0xBFFF:
            if state.basicRomVisible {
                return rom[Int(position)]
            }
            return state.ram[Int(position)]
        case 0xD000...0xDFFF:
            if state.ioVisible {
                if position >= 0xD000 && position <= 0xD3FF {
                    return vic.readByte(UInt8(truncatingBitPattern: position & 0x003F))
                } else if position >= 0xD400 && position <= 0xD7FF {
                    return sid.readByte(UInt8(truncatingBitPattern: position & 0x1F))
                } else if position >= 0xD800 && position <= 0xDBFF {
                    return state.colorRam[Int(position - 0xD800)] & 0x0F | (UInt8(truncatingBitPattern: rand()) << 4)
                } else if position >= 0xDC00 && position <= 0xDCFF {
                    return cia1.readByte(UInt8(truncatingBitPattern: position & 0xF))
                } else if position >= 0xDD00 && position <= 0xDDFF {
                    return cia2.readByte(UInt8(truncatingBitPattern: position & 0xF))
                } else {
                    //TODO: http://www.zimmers.net/anonftp/pub/cbm/documents/chipdata/pal.timing
                    return 0
                }
            } else if state.characterRomVisible {
                return rom[Int(position)]
            } else {
                return state.ram[Int(position)]
            }
        case let position where position >= 0xE000: // was 0xE000...0xFFFF but crashes
            if state.kernalRomVisible {
                return rom[Int(position)]
            }
            return state.ram[Int(position)]
        default:
            return state.ram[Int(position)]
        }
    }
    
    internal func readROMByte(position: UInt16) -> UInt8 {
        return rom[Int(position)]
    }
    
    internal func readRAMByte(position: UInt16) -> UInt8 {
        return state.ram[Int(position)]
    }
    
    internal func readColorRAMByte(position: UInt16) -> UInt8 {
        return state.colorRam[Int(position)] & 0x0F | (UInt8(truncatingBitPattern: rand()) << 4)
    }
    
    internal func readWord(position: UInt16) -> UInt16 {
        return UInt16(readByte(position)) + UInt16(readByte(position + 1)) << 8
    }
    
    //MARK: Write
    
    internal func writeByte(position: UInt16, byte: UInt8) {
        switch position {
        case 0x0000, 0x0001:
            cpu.writeByte(UInt8(truncatingBitPattern: position), byte: byte)
            let port = cpu.readByte(0x01)
            state.kernalRomVisible = ((port & 2) == 2)
            state.basicRomVisible = ((port & 3) == 3)
            state.characterRomVisible = ((port & 4) == 0) && ((port & 3) != 0)
            state.ioVisible = ((port & 4) == 4) && ((port & 3) != 0)
        case 0xD000...0xDFFF:
            if state.ioVisible {
                if position >= 0xD000 && position <= 0xD3FF {
                    vic.writeByte(UInt8(truncatingBitPattern: position & 0x003F), byte: byte)
                } else if position >= 0xD400 && position <= 0xD7FF {
                    sid.writeByte(UInt8(truncatingBitPattern: position & 0x1F), byte: byte)
                } else if position >= 0xD800 && position <= 0xDBFF {
                    state.colorRam[Int(position - 0xD800)] = byte
                } else if position >= 0xDC00 && position <= 0xDCFF {
                    cia1.writeByte(UInt8(truncatingBitPattern: position & 0xF), byte: byte)
                } else if position >= 0xDD00 && position <= 0xDDFF {
                    cia2.writeByte(UInt8(truncatingBitPattern: position & 0xF), byte: byte)
                } else {
                    //TODO: map real addresses
                    state.ram[Int(position)] = byte
                }
            } else {
                state.ram[Int(position)] = byte
            }
        default:
            state.ram[Int(position)] = byte
        }
    }

}
