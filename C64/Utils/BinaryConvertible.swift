//
//  BinaryConvertible.swift
//  C64
//
//  Created by Fabio Ritrovato on 06/06/2016.
//  Copyright © 2016 orange in a day. All rights reserved.
//

class BinaryDump {
    
    private let data: ArraySlice<UInt8>
    private var offset = 0
    
    convenience init(data: [UInt8]) {
        self.init(data: ArraySlice(data))
    }
    
    init(data: ArraySlice<UInt8>) {
        self.data = data
        self.offset = data.startIndex
    }
    
    func nextByte() -> UInt8 {
        let item = data[offset]
        offset += 1
        return item
    }
    
    func next() -> UInt8 {
        return nextByte()
    }
    
    func next<T: BinaryConvertible>() -> T {
        let item = T.extract(BinaryDump(data: data.suffixFrom(offset)))
        offset += Int(item.binarySize)
        return item
    }
    
    func next<T: BinaryConvertible>(numberOfItems: Int) -> [T] {
        return (0..<numberOfItems).map { _ -> T in
            next()
        }
    }
    
}

protocol BinaryDumpable {
    
    func dump() -> [UInt8]
    var binarySize: UInt { get }
    
}

protocol BinaryConvertible: BinaryDumpable {
    
    static func extract(binaryDump: BinaryDump) -> Self
    
}

extension BinaryConvertible {
    
    func dump() -> [UInt8] {
        let m = Mirror(reflecting: self)
        var out = [UInt8]()
        m.children.forEach { label, value in
            if let value = value as? BinaryDumpable {
                out.appendContentsOf(value.dump())
            } else {
                print("Skipping \(label)")
            }
        }
        return out
    }
    
    var binarySize: UInt {
        let m = Mirror(reflecting: self)
        return m.children.flatMap {
            $0.value as? BinaryDumpable
            }.map {
                $0.binarySize
            }.reduce(0, combine: +)
    }
    
}

extension Array: BinaryDumpable {
    
    func dump() -> [UInt8] {
        return flatMap { $0 as? BinaryDumpable }.flatMap { $0.dump() }
    }
    
    var binarySize: UInt {
        return flatMap { $0 as? BinaryDumpable }.reduce(0) { $0 + $1.binarySize }
    }
    
}

extension UInt8: BinaryConvertible {
    
    func dump() -> [UInt8] {
        return [self]
    }
    
    var binarySize: UInt {
        return 1
    }
    
    static func extract(binaryDump: BinaryDump) -> UInt8 {
        return binaryDump.next()
    }
    
}

extension UInt16: BinaryConvertible {
    
    func dump() -> [UInt8] {
        return [UInt8(truncatingBitPattern: self >> 8), UInt8(truncatingBitPattern: self)]
    }
    
    var binarySize: UInt {
        return 2
    }
    
    static func extract(binaryDump: BinaryDump) -> UInt16 {
        return UInt16(binaryDump.next()) << 8 | UInt16(binaryDump.next())
    }
    
}

extension UInt32: BinaryConvertible {
    
    func dump() -> [UInt8] {
        return (0...3).map {
            UInt8(truncatingBitPattern: self >> ($0 * 8))
            }.reverse()
    }
    
    var binarySize: UInt {
        return 4
    }
    
    static func extract(binaryDump: BinaryDump) -> UInt32 {
        return (0...3).reverse().reduce(0) {
            return $0 | UInt32(binaryDump.nextByte()) << ($1 * 8)
        }
    }
    
}

extension Int8: BinaryConvertible {
    
    func dump() -> [UInt8] {
        return [UInt8(bitPattern: self)]
    }
    
    var binarySize: UInt {
        return 1
    }
    
    static func extract(binaryDump: BinaryDump) -> Int8 {
        return Int8(bitPattern: binaryDump.next())
    }
    
}

extension Int: BinaryConvertible {
    
    func dump() -> [UInt8] {
        return (0...7).map {
            UInt8(truncatingBitPattern: self >> ($0 * 8))
        }.reverse()
    }
    
    var binarySize: UInt {
        return 8
    }
    
    static func extract(binaryDump: BinaryDump) -> Int {
        return (0...7).reverse().reduce(0) {
            return $0 | Int(binaryDump.nextByte()) << ($1 * 8)
        }
    }
    
}

extension Bool: BinaryConvertible {
    
    func dump() -> [UInt8] {
        return [self ? 1 : 0]
    }
    
    var binarySize: UInt {
        return 1
    }
    
    static func extract(binaryDump: BinaryDump) -> Bool {
        return binaryDump.nextByte() > 0 ? true : false
    }
    
}

