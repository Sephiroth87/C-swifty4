//
//  Math.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 06/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

func &+(left: UInt16, right: Int8) -> UInt16 {
    return UInt16(bitPattern: Int16(truncatingIfNeeded: Int32(left) + Int32(right)))
}

func &+(left: UInt16, right: UInt8) -> UInt16 {
    return left + UInt16(right)
}

func or(left: Bool, right: Bool) -> Bool {
    return left || right
}
