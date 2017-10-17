//
//  PerformanceTests.swift
//  C-swifty4
//
//  Created by Fabio on 17/11/2016.
//  Copyright © 2016 orange in a day. All rights reserved.
//

import Cocoa
import XCTest
@testable import C64

class PerformanceTests: XCTestCase {
    
    func setupTest(_ filename: String) {
        let expectation = self.expectation(description: filename)
        let romConfig = C64ROMConfiguration(
            kernalData: try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: "kernal", withExtension: nil, subdirectory:"ROM")!),
            basicData: try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: "basic", withExtension: nil, subdirectory:"ROM")!),
            characterData: try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: "chargen", withExtension: nil, subdirectory:"ROM")!))
        let config = C64Configuration(rom: romConfig,
                                      vic: VICConfiguration.pal,
                                      c1541: C1541Configuration(rom: C1541ROMConfiguration(c1541Data: try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: "1541", withExtension: nil, subdirectory:"ROM")!))))
        let c64 = C64(configuration: config)
        c64.setBreakpoint(at: 0xE5CD) {
            c64.setBreakpoint(at: 0xE5CD, handler: nil)
            c64.loadPRGFile(try! Data(contentsOf: Bundle(for: self.classForCoder).url(forResource: filename, withExtension: "prg", subdirectory: "Resources/Lorenz 2.15")!))
                c64.run()
                c64.loadString("RUN\n")
            }
            c64.setBreakpoint(at: 0xE16F) {
                expectation.fulfill()
            }
            c64.run()
            self.waitForExpectations(timeout: 10) { _ in
                self.stopMeasuring()
            }
    }
    
    func test_cputiming_performance() {
        measureMetrics(PerformanceTests.defaultPerformanceMetrics, automaticallyStartMeasuring: true) {
            self.setupTest("cputiming")
        }
    }
    
    func test_irq_performance() {
        measureMetrics(PerformanceTests.defaultPerformanceMetrics, automaticallyStartMeasuring: true) {
            self.setupTest("irq")
        }
    }
    
    func test_nmi_performance() {
        measureMetrics(PerformanceTests.defaultPerformanceMetrics, automaticallyStartMeasuring: true) {
            self.setupTest("nmi")
        }
    }
    
}
