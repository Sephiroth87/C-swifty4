//
//  FixedArray.swift
//  C64
//
//  Created by Fabio on 11/03/2020.
//  Copyright © 2020 orange in a day. All rights reserved.
//

import Foundation

// This types allow us to inline array directly inside structs, thus giving a great speed boost due to:
// - less overhead, and no objc bridging
// - internal storage is not class, so no retain/release needed when accessing
// - because of that, also, exclusive access is guaranteed and swift_beginAccess/swift_endAccess are avoided at runtime

struct FixedArray8<T>: RandomAccessCollection, MutableCollection {
    
    typealias Values = (T, T, T, T, T, T, T, T)
    
    private var storage: Values
    
    init(repeating v: T) {
        storage = (v, v, v, v, v, v, v, v)
    }
    
    init(values: Values) {
        storage = values
    }
    
    subscript(i: Int) -> T {
        @inline(__always) get {
            return withUnsafeBytes(of: storage) { rawBuffer in
                let buffer = UnsafeBufferPointer<T>(start: rawBuffer.baseAddress!.assumingMemoryBound(to: T.self), count: 8)
                return buffer[i]
            }
        }
        @inline(__always) set(newValue) {
            withUnsafeMutableBytes(of: &storage) { rawBuffer in
                let buffer = UnsafeMutableBufferPointer<T>(start: rawBuffer.baseAddress!.assumingMemoryBound(to: T.self), count: 8)
                buffer[i] = newValue
            }
        }
    }
    
    var startIndex: Int { return 0 }
    
    var endIndex: Int { return 8 }

}

struct FixedArray40<T>: RandomAccessCollection, MutableCollection {
    
    typealias Values = (
    T, T, T, T, T, T, T, T,
    T, T, T, T, T, T, T, T,
    T, T, T, T, T, T, T, T,
    T, T, T, T, T, T, T, T,
    T, T, T, T, T, T, T, T
    )
    
    private var storage: Values
    
    init(repeating v: T) {
        storage = (
            v, v, v, v, v, v, v, v,
            v, v, v, v, v, v, v, v,
            v, v, v, v, v, v, v, v,
            v, v, v, v, v, v, v, v,
            v, v, v, v, v, v, v, v
        )
    }
    
    init(values: Values) {
        storage = values
    }
    
    subscript(i: Int) -> T {
        @inline(__always) get {
            return withUnsafeBytes(of: storage) { rawBuffer in
                let buffer = UnsafeBufferPointer<T>(start: rawBuffer.baseAddress!.assumingMemoryBound(to: T.self), count: 40)
                return buffer[i]
            }
        }
        @inline(__always) set(newValue) {
            withUnsafeMutableBytes(of: &storage) { rawBuffer in
                let buffer = UnsafeMutableBufferPointer<T>(start: rawBuffer.baseAddress!.assumingMemoryBound(to: T.self), count: 40)
                buffer[i] = newValue
            }
        }
    }
    
    var startIndex: Int { return 0 }
    
    var endIndex: Int { return 40 }

}
