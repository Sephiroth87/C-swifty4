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

final internal class C64Memory: Memory {
    
    internal weak var cpu: CPU!
    internal weak var cia1: CIA1!
    internal weak var cia2: CIA2!
    internal weak var sid: SID!
    internal weak var vic: VIC!
    internal var crashHandler: C64CrashHandler?
   
    private var ram: [UInt8] = [UInt8](count: 0x10000, repeatedValue: 0)
    private var rom: [UInt8] = [UInt8](count: 0x10000, repeatedValue: 0)
    private var colorRam: [UInt8] = [UInt8](count: 1024, repeatedValue: 0)
    
    //MARK: Helpers
    private var characterRomVisible = false
    private var kernalRomVisible = true
    private var basicRomVisible = true
    private var ioVisible = true
    //MARK: -
    
    init() {
        // RAM powerup pattern
        for i in 0..<512 {
            for j in 0..<64 {
                ram[128 * i + 64 + j] = 0xFF
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
            ram[position+i] = data[i]
        }
    }
    
    //MARK: Read
    
    internal func readByte(position: UInt16) -> UInt8 {
        switch position {
        case 0x1:
            //TODO: temp return value
            return self.cpu.portDirection & self.cpu.port
        case 0xA000...0xBFFF:
            if basicRomVisible {
                return rom[Int(position)]
            }
            return ram[Int(position)]
        case 0xD000...0xDFFF:
            if ioVisible {
                if position >= 0xD000 && position <= 0xD3FF {
                    return self.vic.readByte(UInt8(truncatingBitPattern: position & 0x003F))
                } else if position >= 0xD400 && position <= 0xD7FF {
                    return self.sid.readByte(UInt8(truncatingBitPattern: position & 0x1F))
                } else if position >= 0xD800 && position <= 0xDBFF {
                    return colorRam[Int(position - 0xD800)] & 0x0F | (UInt8(truncatingBitPattern: rand()) << 4)
                } else if position >= 0xDC00 && position <= 0xDCFF {
                    return self.cia1.readByte(UInt8(truncatingBitPattern: position & 0xF))
                } else if position >= 0xDD00 && position <= 0xDDFF {
                    return self.cia2.readByte(UInt8(truncatingBitPattern: position & 0xF))
                } else {
                    crashHandler?("Unknown I/O address " + String(position, radix: 16, uppercase: true))
                    return 0
                }
            } else if characterRomVisible {
                return rom[Int(position)]
            } else {
                return ram[Int(position)]
            }
        case let position where position >= 0xE000: // was 0xE000...0xFFFF but crashes
            if kernalRomVisible {
                return rom[Int(position)]
            }
            return ram[Int(position)]
        default:
            return ram[Int(position)]
        }
    }
    
    internal func readROMByte(position: UInt16) -> UInt8 {
        return rom[Int(position)]
    }
    
    internal func readRAMByte(position: UInt16) -> UInt8 {
        return ram[Int(position)]
    }
    
    internal func readColorRAMByte(position: UInt16) -> UInt8 {
        return colorRam[Int(position)] & 0x0F | (UInt8(truncatingBitPattern: rand()) << 4)
    }
    
    internal func readWord(position: UInt16) -> UInt16 {
        return UInt16(readByte(position)) + UInt16(readByte(position + 1)) << 8
    }
    
    
    //MARK: Write
    
    internal func writeByte(position: UInt16, byte: UInt8) {
        switch position {
        case 0x00:
            self.cpu.portDirection = byte
        case 0x01:
            self.cpu.port = byte
            let newPort = self.cpu.port
            kernalRomVisible = ((newPort & 2) == 2)
            basicRomVisible = ((newPort & 3) == 3)
            characterRomVisible = ((newPort & 4) == 0) && ((newPort & 3) != 0)
            ioVisible = ((newPort & 4) == 4) && ((newPort & 3) != 0)
        case 0xD000...0xDFFF:
            if ioVisible {
                if position >= 0xD000 && position <= 0xD3FF {
                    self.vic.writeByte(UInt8(truncatingBitPattern: position & 0x003F), byte: byte)
                } else if position >= 0xD400 && position <= 0xD7FF {
                    self.sid.writeByte(UInt8(truncatingBitPattern: position & 0x1F), byte: byte)
                } else if position >= 0xD800 && position <= 0xDBFF {
                    colorRam[Int(position - 0xD800)] = byte
                } else if position >= 0xDC00 && position <= 0xDCFF {
                    self.cia1.writeByte(UInt8(truncatingBitPattern: position & 0xF), byte: byte)
                } else if position >= 0xDD00 && position <= 0xDDFF {
                    self.cia2.writeByte(UInt8(truncatingBitPattern: position & 0xF), byte: byte)
                } else {
                    //TODO: map real addresses
                    self.ram[Int(position)] = byte
                }
            } else {
                self.ram[Int(position)] = byte
            }
        default:
            self.ram[Int(position)] = byte
        }
    }

}
