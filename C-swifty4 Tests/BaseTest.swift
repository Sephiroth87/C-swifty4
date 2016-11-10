//
//  BaseTest.swift
//  C-swifty4
//
//  Created by Fabio on 10/11/2016.
//  Copyright © 2016 orange in a day. All rights reserved.
//

import Cocoa
import XCTest
@testable import C64

class BaseTest: XCTestCase {
    
    internal var c64: C64!
    internal var expectation: XCTestExpectation!
    fileprivate var fileName: String!
    
    internal var subdirectory: String {
        return ""
    }
    internal var timeout: TimeInterval {
        return 100
    }
    
    
    func setupTest(_ filename: String) {
        self.fileName = filename
        expectation = self.expectation(description: name!)
        c64.run()
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    override func setUp() {
        super.setUp()
        c64 = C64(kernalData: try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: "kernal", withExtension: nil, subdirectory:"ROM")!),
                  basicData: try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: "basic", withExtension: nil, subdirectory:"ROM")!),
                  characterData: try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: "chargen", withExtension: nil, subdirectory:"ROM")!),
                  c1541Data: try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: "1541", withExtension: nil, subdirectory:"ROM")!))
        c64.delegate = self
        c64.setBreakpoint(0xE5CD)
    }

}

extension BaseTest: C64Delegate {
    
    func C64DidBreak(_ c64: C64) {
        if c64.debugInfo()["pc"] == "e5cd" {
            c64.removeBreakpoint(0xE5CD)
            c64.loadPRGFile(try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: fileName, withExtension: "prg", subdirectory: subdirectory)!))
            c64.setBreakpoint(0xE16F)
            c64.run()
            c64.loadString("RUN\n")
        }
    }
    
    func C64DidCrash(_ c64: C64) {
        XCTAssert(false, "Crash")
        expectation.fulfill()
    }
    
    func C64VideoFrameReady(_ c64: C64) {}
    
}
