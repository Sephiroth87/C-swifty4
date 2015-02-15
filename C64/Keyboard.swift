//
//  Keyboard.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 13/01/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

public enum SpecialKey: UInt16 {
    case Return    = 0x0001
    case Shift     = 0x0107
    case Backspace = 0x0000
}

final internal class Keyboard {
    
    private var matrix = [UInt8](count: 8, repeatedValue: 0xFF)
    private let keyMap: [UInt8: UInt16] = [
        UInt8("a") : UInt16(0x0102),
        UInt8("b") : UInt16(0x0304),
        UInt8("c") : UInt16(0x0204),
        UInt8("d") : UInt16(0x0202),
        UInt8("e") : UInt16(0x0106),
        UInt8("f") : UInt16(0x0205),
        UInt8("g") : UInt16(0x0302),
        UInt8("h") : UInt16(0x0305),
        UInt8("i") : UInt16(0x0401),
        UInt8("j") : UInt16(0x0402),
        UInt8("k") : UInt16(0x0405),
        UInt8("l") : UInt16(0x0502),
        UInt8("m") : UInt16(0x0404),
        UInt8("n") : UInt16(0x0407),
        UInt8("o") : UInt16(0x0406),
        UInt8("p") : UInt16(0x0501),
        UInt8("q") : UInt16(0x0706),
        UInt8("r") : UInt16(0x0201),
        UInt8("s") : UInt16(0x0105),
        UInt8("t") : UInt16(0x0206),
        UInt8("u") : UInt16(0x0306),
        UInt8("v") : UInt16(0x0307),
        UInt8("w") : UInt16(0x0101),
        UInt8("x") : UInt16(0x0207),
        UInt8("y") : UInt16(0x0301),
        UInt8("z") : UInt16(0x0104),
        UInt8("1") : UInt16(0x0700),
        UInt8("2") : UInt16(0x0703),
        UInt8("3") : UInt16(0x0100),
        UInt8("4") : UInt16(0x0103),
        UInt8("5") : UInt16(0x0200),
        UInt8("6") : UInt16(0x0203),
        UInt8("7") : UInt16(0x0300),
        UInt8("8") : UInt16(0x0303),
        UInt8("9") : UInt16(0x0400),
        UInt8("0") : UInt16(0x0403),
        UInt8(" ") : UInt16(0x0704),
        UInt8(":") : UInt16(0x0505),
        UInt8(".") : UInt16(0x0504),
        UInt8(",") : UInt16(0x0507),
        UInt8(";") : UInt16(0x0602),
        UInt8("=") : UInt16(0x0605),
        UInt8("+") : UInt16(0x0500),
        UInt8("-") : UInt16(0x0503),
        UInt8("*") : UInt16(0x0601),
        // Shifted chars
        UInt8("\"") : UInt16(0x1703),
        UInt8("(") : UInt16(0x1303),
        UInt8(")") : UInt16(0x1400),
        UInt8("?") : UInt16(0x1607),
        UInt8("$") : UInt16(0x1103)
    ]
    
    private func pressKey(keyValue: UInt16) {
        let row = Int(keyValue >> 8)
        matrix[row] &= 0xFF - UInt8(1 << (keyValue & 0xFF))
    }
    
    internal func pressKey(key: UInt8) {
        if var keyValue = keyMap[key] {
            if keyValue & 0xF000 != 0 {
                pressSpecialKey(.Shift)
                keyValue &= 0x0FFF
            }
            pressKey(keyValue)
        }
    }
    
    internal func pressSpecialKey(key: SpecialKey) {
        pressKey(key.rawValue)
    }
    
    private func releaseKey(keyValue: UInt16) {
        let row = Int(keyValue >> 8)
        matrix[row] |= UInt8(1 << (keyValue & 0xFF))
    }
    
    internal func releaseKey(key: UInt8) {
        if var keyValue = keyMap[key] {
            if keyValue & 0xF000 != 0 {
                releaseSpecialKey(.Shift)
                keyValue &= 0x0FFF
            }
            releaseKey(keyValue)
        }
    }
    
    internal func releaseSpecialKey(key: SpecialKey) {
        releaseKey(key.rawValue)
    }
    
    internal func readMatrix(mask: UInt8) -> UInt8 {
        var values: UInt8 = 0xFF
        for i in 0..<8 {
            if mask & UInt8(1 << i) == 0 {
                values = values & matrix[i]
            }
        }
        return values
    }
    
}
