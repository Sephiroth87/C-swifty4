//
//  C1541Memory.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 17/04/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

final internal class C1541Memory: Memory {
    
    internal weak var via1: VIA1!
    internal weak var via2: VIA2!
    
    private var memory: [UInt8] = [UInt8](count: 0x10000, repeatedValue: 0)
    
    internal func writeC1541Data(data: UnsafePointer<UInt8>) {
        for i in 0..<0x4000 {
            memory[0xC000+i] = data[i]
        }
    }
    
    //MARK: Read
    
    internal func readByte(position: UInt16) -> UInt8 {
        if position < 0x1000 {
            return memory[Int(position & 0x07FF)]
        } else if position & 0xFC00 == 0x1800 { // Can't find any reference for this repeating, but everyone else is doing it...
            return via1.readByte(UInt8(truncatingBitPattern: position & 0x000F))
        } else if position & 0xFC00 == 0x1C00 {
            return via2.readByte(UInt8(truncatingBitPattern: position & 0x000F))
        }
        return memory[Int(position)]
    }
    
    internal func readWord(position: UInt16) -> UInt16 {
        return UInt16(readByte(position)) + UInt16(readByte(position + 1)) << 8
    }
    
    //MARK: Write
    
    internal func writeByte(position: UInt16, byte: UInt8) {
        if position < 0x1000 {
            memory[Int(position & 0x07FF)] = byte
        } else if position & 0xFC00 == 0x1800 { // Same as above...
            via1.writeByte(UInt8(truncatingBitPattern: position & 0x000F), byte: byte)
        } else if position & 0xFC00 == 0x1C00 {
            via2.writeByte(UInt8(truncatingBitPattern: position & 0x000F), byte: byte)
        }
    }
    
}
