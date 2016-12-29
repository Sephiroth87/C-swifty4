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
        let romConfig = C64ROMConfiguration(
            kernalData: try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: "kernal", withExtension: nil, subdirectory:"ROM")!),
            basicData: try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: "basic", withExtension: nil, subdirectory:"ROM")!),
            characterData: try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: "chargen", withExtension: nil, subdirectory:"ROM")!))
        let config = C64Configuration(rom: romConfig,
                                      vic: VICConfiguration.pal,
                                      c1541: C1541Configuration(rom: C1541ROMConfiguration(c1541Data: try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: "1541", withExtension: nil, subdirectory:"ROM")!))))
        c64 = C64(configuration: config)
        c64.delegate = self
        c64.setBreakpoint(at: 0xE5CD) {
            self.c64.setBreakpoint(at: 0xE5CD, handler: nil)
            self.c64.loadPRGFile(try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: self.fileName, withExtension: "prg", subdirectory: self.subdirectory)!))
            self.c64.run()
            self.c64.loadString("RUN\n")
        }
    }

}

extension BaseTest: C64Delegate {
    
    func C64DidBreak(_ c64: C64) {}
    
    func C64DidCrash(_ c64: C64) {
        XCTAssert(false, "Crash")
        expectation.fulfill()
    }
    
    func C64VideoFrameReady(_ c64: C64) {}
    
}
