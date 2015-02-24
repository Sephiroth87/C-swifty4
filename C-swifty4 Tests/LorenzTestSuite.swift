//
//  LorenzTestSuite.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 24/02/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import Cocoa
import XCTest
import C64

class LorenzTestSuite: XCTestCase {
    
    private var c64: C64!
    private var expectation: XCTestExpectation!
    private var fileName: String!
    
    static let block : @objc_block (LorenzTestSuite) -> Void = { (test: LorenzTestSuite) -> Void in
        test.expectation = test.expectationWithDescription(test.name)
        test.c64.run()
        test.waitForExpectationsWithTimeout(100, handler: nil)
    }
    
    override func setUp() {
        super.setUp()
        c64 = C64(kernalData: NSData(contentsOfFile: NSBundle(forClass: self.classForCoder).pathForResource("kernal", ofType: nil, inDirectory:"ROM")!)!,
            basicData: NSData(contentsOfFile: NSBundle(forClass: self.classForCoder).pathForResource("basic", ofType: nil, inDirectory:"ROM")!)!,
            characterData: NSData(contentsOfFile: NSBundle(forClass: self.classForCoder).pathForResource("chargen", ofType: nil, inDirectory:"ROM")!)!)
        c64.delegate = self
        c64.setBreakpoint(0xE5CD)
        c64.setBreakpoint(0xFFE4)
    }
    
    override class func defaultTestSuite() -> XCTestSuite! {
        let suite = XCTestSuite(name: "Lorenz Test Suite")
        if let testFiles = NSBundle(forClass: self.self).URLsForResourcesWithExtension("prg", subdirectory: "Resources/Lorenz 2.15") as? [NSURL] {
            for fileUrl in testFiles {
                let testName = fileUrl.lastPathComponent!.stringByDeletingPathExtension
                let selector = NSSelectorFromString(testName)
                class_addMethod(self.self, selector, imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self)), "v16@0:8")
                let test = LorenzTestSuite(selector: selector)
                test.fileName = testName
                suite.addTest(test)
            }
        }
        return suite
    }
    
}

extension LorenzTestSuite: C64Delegate {
    
    func C64DidBreak(c64: C64) {
        if c64.debugInfo()["pc"] == "e5cd" {
            c64.removeBreakpoint(0xE5CD)
            c64.loadPRGFile(NSData(contentsOfFile: NSBundle(forClass: self.classForCoder).pathForResource(fileName, ofType: "prg", inDirectory:"Resources/Lorenz 2.15")!)!)
            c64.setBreakpoint(0xE16F)
            c64.run()
            c64.loadString("RUN\n")
        } else if c64.debugInfo()["pc"] == "e16f" {
            expectation.fulfill()
            XCTAssert(true, "Pass")
        } else if c64.debugInfo()["pc"] == "ffe4" {
            XCTAssert(false, "Fail")
            expectation.fulfill()
        }
    }
    
    func C64VideoFrameReady(c64: C64) {
        
    }
    
}
