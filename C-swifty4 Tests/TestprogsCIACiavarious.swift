//
//  TestprogsCIACiavarious.swift
//  C-swifty4
//
//  Created by Fabio on 10/11/2016.
//  Copyright © 2016 orange in a day. All rights reserved.
//

import Cocoa
import XCTest
@testable import C64

class TestprogsCIACiavarious: BaseTest {
    
    override var subdirectory: String {
        return "Resources/testprogs/CIA/ciavarious"
    }
    
    func test_cia1() {
        setupTest("cia1")
    }
    
    func test_cia2() {
        setupTest("cia2")
    }
    
    func test_cia3() {
        setupTest("cia3")
    }
    
    func test_cia3a() {
        setupTest("cia3a")
    }
    
    func test_cia4() {
        setupTest("cia4")
    }
    
    func test_cia5() {
        setupTest("cia5")
    }
    
    func test_cia6() {
        setupTest("cia6")
    }
    
    func test_cia7() {
        setupTest("cia7")
    }
    
    func test_cia8() {
        setupTest("cia8")
    }
    
    func test_cia9() {
        setupTest("cia9")
    }
    
    func test_cia10() {
        setupTest("cia10")
    }
    
    func test_cia11() {
        setupTest("cia11")
    }
    
    func test_cia12() {
        setupTest("cia12")
    }
    
    func test_cia13() {
        setupTest("cia13")
    }
    
    func test_cia14() {
        setupTest("cia14")
    }
    
    func test_cia15() {
        setupTest("cia15")
    }
    
    override func C64DidBreak(_ c64: C64) {
        super.C64DidBreak(c64)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
            XCTAssert(c64.memory.readByte(0xD020) & 0x0F == 5)
            self.expectation.fulfill()
        }
    }
    
}
