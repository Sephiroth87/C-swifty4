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
    
    func setupTest(filename: String) {
        self.fileName = filename
        expectation = expectationWithDescription(name!)
        c64.run()
        waitForExpectationsWithTimeout(100, handler: nil)
    }
    
    override func setUp() {
        super.setUp()
        c64 = C64(kernalData: NSData(contentsOfFile: NSBundle(forClass: self.classForCoder).pathForResource("kernal", ofType: nil, inDirectory:"ROM")!)!,
            basicData: NSData(contentsOfFile: NSBundle(forClass: self.classForCoder).pathForResource("basic", ofType: nil, inDirectory:"ROM")!)!,
            characterData: NSData(contentsOfFile: NSBundle(forClass: self.classForCoder).pathForResource("chargen", ofType: nil, inDirectory:"ROM")!)!,
            c1541Data: NSData(contentsOfFile: NSBundle(forClass: self.classForCoder).pathForResource("1541", ofType: nil, inDirectory:"ROM")!)!)
        c64.delegate = self
        c64.setBreakpoint(0xE5CD)
        c64.setBreakpoint(0xFFE4)
    }
    
    func test_adca() {
        setupTest("adca")
    }
    
    func test_adcax() {
        setupTest("adcax")
    }
    
    func test_adcay() {
        setupTest("adcay")
    }
    
    func test_adcb() {
        setupTest("adcb")
    }
    
    func test_adcix() {
        setupTest("adcix")
    }
    
    func test_adciy() {
        setupTest("adciy")
    }
    
    func test_adcz() {
        setupTest("adcz")
    }
    
    func test_adczx() {
        setupTest("adczx")
    }
    
    func test_alrb() {
        setupTest("alrb")
    }
    
    func test_ancb() {
        setupTest("ancb")
    }
    
    func test_anda() {
        setupTest("anda")
    }
    
    func test_andax() {
        setupTest("andax")
    }
    
    func test_anday() {
        setupTest("anday")
    }
    
    func test_andb() {
        setupTest("andb")
    }
    
    func test_andix() {
        setupTest("andix")
    }
    
    func test_andiy() {
        setupTest("andiy")
    }
    
    func test_andz() {
        setupTest("andz")
    }
    
    func test_andzx() {
        setupTest("andzx")
    }
    
    func test_aneb() {
        setupTest("aneb")
    }
    
    func test_arrb() {
        setupTest("arrb")
    }
    
    func test_asla() {
        setupTest("asla")
    }
    
    func test_aslax() {
        setupTest("aslax")
    }
    
    func test_asln() {
        setupTest("asln")
    }
    
    func test_aslz() {
        setupTest("aslz")
    }
    
    func test_aslzx() {
        setupTest("aslzx")
    }
    
    func test_asoa() {
        setupTest("asoa")
    }
    
    func test_asoax() {
        setupTest("asoax")
    }
    
    func test_asoay() {
        setupTest("asoay")
    }
    
    func test_asoix() {
        setupTest("asoix")
    }
    
    func test_asoiy() {
        setupTest("asoiy")
    }
    
    func test_asoz() {
        setupTest("asoz")
    }
    
    func test_asozx() {
        setupTest("asozx")
    }
    
    func test_axsa() {
        setupTest("axsa")
    }
    
    func test_axsix() {
        setupTest("axsix")
    }
    
    func test_axsz() {
        setupTest("axsz")
    }
    
    func test_axszy() {
        setupTest("axszy")
    }
    
    func test_bccr() {
        setupTest("bccr")
    }
    
    func test_bcsr() {
        setupTest("bcsr")
    }
    
    func test_beqr() {
        setupTest("beqr")
    }
    
    func test_bita() {
        setupTest("bita")
    }
    
    func test_bitz() {
        setupTest("bitz")
    }
    
    func test_bmir() {
        setupTest("bmir")
    }
    
    func test_bner() {
        setupTest("bner")
    }
    
    func test_bplr() {
        setupTest("bplr")
    }
    
    func test_branchwrap() {
        setupTest("branchwrap")
    }
    
    func test_brkn() {
        setupTest("brkn")
    }
    
    func test_bvcr() {
        setupTest("bvcr")
    }
    
    func test_bvsr() {
        setupTest("bvsr")
    }
    
    func test_cia1pb6() {
        setupTest("cia1pb6")
    }
    
    func test_cia1pb7() {
        setupTest("cia1pb7")
    }
    
    func test_cia1ta() {
        setupTest("cia1ta")
    }
    
    func test_cia1tab() {
        setupTest("cia1tab")
    }
    
    func test_cia1tabnew() {
        setupTest("cia1tabnew")
    }
    
    func test_cia1tanew() {
        setupTest("cia1tanew")
    }
    
    func test_cia1tb() {
        setupTest("cia1tb")
    }
    
    func test_cia1tb123() {
        setupTest("cia1tb123")
    }
    
    func test_cia1tbnew() {
        setupTest("cia1tbnew")
    }
    
    func test_cia2pb6() {
        setupTest("cia2pb6")
    }
    
    func test_cia2pb7() {
        setupTest("cia2pb7")
    }
    
    func test_cia2ta() {
        setupTest("cia2ta")
    }
    
    func test_cia2tanew() {
        setupTest("cia2tanew")
    }
    
    func test_cia2tb() {
        setupTest("cia2tb")
    }
    
    func test_cia2tb123() {
        setupTest("cia2tb123")
    }
    
    func test_cia2tbnew() {
        setupTest("cia2tbnew")
    }
    
    func test_clcn() {
        setupTest("clcn")
    }
    
    func test_cldn() {
        setupTest("cldn")
    }
    
    func test_clin() {
        setupTest("clin")
    }
    
    func test_clvn() {
        setupTest("clvn")
    }
    
    func test_cmpa() {
        setupTest("cmpa")
    }
    
    func test_cmpax() {
        setupTest("cmpax")
    }
    
    func test_cmpay() {
        setupTest("cmpay")
    }
    
    func test_cmpb() {
        setupTest("cmpb")
    }
    
    func test_cmpix() {
        setupTest("cmpix")
    }
    
    func test_cmpiy() {
        setupTest("cmpiy")
    }
    
    func test_cmpz() {
        setupTest("cmpz")
    }
    
    func test_cmpzx() {
        setupTest("cmpzx")
    }
    
    func test_cntdef() {
        setupTest("cntdef")
    }
    
    func test_cnto2() {
        setupTest("cnto2")
    }
    
    func test_cpuport() {
        setupTest("cpuport")
    }
    
    func test_cputiming() {
        setupTest("cputiming")
    }
    
    func test_cpxa() {
        setupTest("cpxa")
    }
    
    func test_cpxb() {
        setupTest("cpxb")
    }
    
    func test_cpxz() {
        setupTest("cpxz")
    }
    
    func test_cpya() {
        setupTest("cpya")
    }
    
    func test_cpyb() {
        setupTest("cpyb")
    }
    
    func test_cpyz() {
        setupTest("cpyz")
    }
    
    func test_dcma() {
        setupTest("dcma")
    }
    
    func test_dcmax() {
        setupTest("dcmax")
    }
    
    func test_dcmay() {
        setupTest("dcmay")
    }
    
    func test_dcmix() {
        setupTest("dcmix")
    }
    
    func test_dcmiy() {
        setupTest("dcmiy")
    }
    
    func test_dcmz() {
        setupTest("dcmz")
    }
    
    func test_dcmzx() {
        setupTest("dcmzx")
    }
    
    func test_deca() {
        setupTest("deca")
    }
    
    func test_decax() {
        setupTest("decax")
    }
    
    func test_decz() {
        setupTest("decz")
    }
    
    func test_deczx() {
        setupTest("deczx")
    }
    
    func test_dexn() {
        setupTest("dexn")
    }
    
    func test_deyn() {
        setupTest("deyn")
    }
    
    func test_eora() {
        setupTest("eora")
    }
    
    func test_eorax() {
        setupTest("eorax")
    }
    
    func test_eoray() {
        setupTest("eoray")
    }
    
    func test_eorb() {
        setupTest("eorb")
    }
    
    func test_eorix() {
        setupTest("eorix")
    }
    
    func test_eoriy() {
        setupTest("eoriy")
    }
    
    func test_eorz() {
        setupTest("eorz")
    }
    
    func test_eorzx() {
        setupTest("eorzx")
    }
    
    func test_flipos() {
        setupTest("flipos")
    }
    
    func test_icr01() {
        setupTest("icr01")
    }
    
    func test_icr01new() {
        setupTest("icr01new")
    }
    
    func test_imr() {
        setupTest("imr")
    }
    
    func test_imrnew() {
        setupTest("imrnew")
    }
    
    func test_inca() {
        setupTest("inca")
    }
    
    func test_incax() {
        setupTest("incax")
    }
    
    func test_incz() {
        setupTest("incz")
    }
    
    func test_inczx() {
        setupTest("inczx")
    }
    
    func test_insa() {
        setupTest("insa")
    }
    
    func test_insax() {
        setupTest("insax")
    }
    
    func test_insay() {
        setupTest("insay")
    }
    
    func test_insix() {
        setupTest("insix")
    }
    
    func test_insiy() {
        setupTest("insiy")
    }
    
    func test_insz() {
        setupTest("insz")
    }
    
    func test_inszx() {
        setupTest("inszx")
    }
    
    func test_inxn() {
        setupTest("inxn")
    }
    
    func test_inyn() {
        setupTest("inyn")
    }
    
    func test_irq() {
        setupTest("irq")
    }
    
    func test_irqnew() {
        setupTest("irqnew")
    }
    
    func test_jmpi() {
        setupTest("jmpi")
    }
    
    func test_jmpw() {
        setupTest("jmpw")
    }
    
    func test_jsrw() {
        setupTest("jsrw")
    }
    
    func test_lasay() {
        setupTest("lasay")
    }
    
    func test_laxa() {
        setupTest("laxa")
    }
    
    func test_laxay() {
        setupTest("laxay")
    }
    
    func test_laxix() {
        setupTest("laxix")
    }
    
    func test_laxiy() {
        setupTest("laxiy")
    }
    
    func test_laxz() {
        setupTest("laxz")
    }
    
    func test_laxzy() {
        setupTest("laxzy")
    }
    
    func test_ldaa() {
        setupTest("ldaa")
    }
    
    func test_ldaax() {
        setupTest("ldaax")
    }
    
    func test_ldaay() {
        setupTest("ldaay")
    }
    
    func test_ldab() {
        setupTest("ldab")
    }
    
    func test_ldaix() {
        setupTest("ldaix")
    }
    
    func test_ldaiy() {
        setupTest("ldaiy")
    }
    
    func test_ldaz() {
        setupTest("ldaz")
    }
    
    func test_ldazx() {
        setupTest("ldazx")
    }
    
    func test_ldxa() {
        setupTest("ldxa")
    }
    
    func test_ldxay() {
        setupTest("ldxay")
    }
    
    func test_ldxb() {
        setupTest("ldxb")
    }
    
    func test_ldxz() {
        setupTest("ldxz")
    }
    
    func test_ldxzy() {
        setupTest("ldxzy")
    }
    
    func test_ldya() {
        setupTest("ldya")
    }
    
    func test_ldyax() {
        setupTest("ldyax")
    }
    
    func test_ldyb() {
        setupTest("ldyb")
    }
    
    func test_ldyz() {
        setupTest("ldyz")
    }
    
    func test_ldyzx() {
        setupTest("ldyzx")
    }
    
    func test_loadth() {
        setupTest("loadth")
    }
    
    func test_lsea() {
        setupTest("lsea")
    }
    
    func test_lseax() {
        setupTest("lseax")
    }
    
    func test_lseay() {
        setupTest("lseay")
    }
    
    func test_lseix() {
        setupTest("lseix")
    }
    
    func test_lseiy() {
        setupTest("lseiy")
    }
    
    func test_lsez() {
        setupTest("lsez")
    }
    
    func test_lsezx() {
        setupTest("lsezx")
    }
    
    func test_lsra() {
        setupTest("lsra")
    }
    
    func test_lsrax() {
        setupTest("lsrax")
    }
    
    func test_lsrn() {
        setupTest("lsrn")
    }
    
    func test_lsrz() {
        setupTest("lsrz")
    }
    
    func test_lsrzx() {
        setupTest("lsrzx")
    }
    
    func test_lxab() {
        setupTest("lxab")
    }
    
    func test_mmu() {
        setupTest("mmu")
    }
    
    func test_mmufetch() {
        setupTest("mmufetch")
    }
    
    func test_nextdisk1() {
        setupTest("nextdisk1")
    }
    
    func test_nextdisk2() {
        setupTest("nextdisk2")
    }
    
    func test_nmi() {
        setupTest("nmi")
    }
    
    func test_nminew() {
        setupTest("nminew")
    }
    
    func test_nopa() {
        setupTest("nopa")
    }
    
    func test_nopax() {
        setupTest("nopax")
    }
    
    func test_nopb() {
        setupTest("nopb")
    }
    
    func test_nopn() {
        setupTest("nopn")
    }
    
    func test_nopz() {
        setupTest("nopz")
    }
    
    func test_nopzx() {
        setupTest("nopzx")
    }
    
    func test_oneshot() {
        setupTest("oneshot")
    }
    
    func test_oraa() {
        setupTest("oraa")
    }
    
    func test_oraax() {
        setupTest("oraax")
    }
    
    func test_oraay() {
        setupTest("oraay")
    }
    
    func test_orab() {
        setupTest("orab")
    }
    
    func test_oraix() {
        setupTest("oraix")
    }
    
    func test_oraiy() {
        setupTest("oraiy")
    }
    
    func test_oraz() {
        setupTest("oraz")
    }
    
    func test_orazx() {
        setupTest("orazx")
    }
    
    func test_phan() {
        setupTest("phan")
    }
    
    func test_phpn() {
        setupTest("phpn")
    }
    
    func test_plan() {
        setupTest("plan")
    }
    
    func test_plpn() {
        setupTest("plpn")
    }
    
    func test_rlaa() {
        setupTest("rlaa")
    }
    
    func test_rlaax() {
        setupTest("rlaax")
    }
    
    func test_rlaay() {
        setupTest("rlaay")
    }
    
    func test_rlaix() {
        setupTest("rlaix")
    }
    
    func test_rlaiy() {
        setupTest("rlaiy")
    }
    
    func test_rlaz() {
        setupTest("rlaz")
    }
    
    func test_rlazx() {
        setupTest("rlazx")
    }
    
    func test_rola() {
        setupTest("rola")
    }
    
    func test_rolax() {
        setupTest("rolax")
    }
    
    func test_roln() {
        setupTest("roln")
    }
    
    func test_rolz() {
        setupTest("rolz")
    }
    
    func test_rolzx() {
        setupTest("rolzx")
    }
    
    func test_rora() {
        setupTest("rora")
    }
    
    func test_rorax() {
        setupTest("rorax")
    }
    
    func test_rorn() {
        setupTest("rorn")
    }
    
    func test_rorz() {
        setupTest("rorz")
    }
    
    func test_rorzx() {
        setupTest("rorzx")
    }
    
    func test_rraa() {
        setupTest("rraa")
    }
    
    func test_rraax() {
        setupTest("rraax")
    }
    
    func test_rraay() {
        setupTest("rraay")
    }
    
    func test_rraix() {
        setupTest("rraix")
    }
    
    func test_rraiy() {
        setupTest("rraiy")
    }
    
    func test_rraz() {
        setupTest("rraz")
    }
    
    func test_rrazx() {
        setupTest("rrazx")
    }
    
    func test_rtin() {
        setupTest("rtin")
    }
    
    func test_rtsn() {
        setupTest("rtsn")
    }
    
    func test_sbca() {
        setupTest("sbca")
    }
    
    func test_sbcax() {
        setupTest("sbcax")
    }
    
    func test_sbcay() {
        setupTest("sbcay")
    }
    
    func test_sbcb_eb() {
        setupTest("sbcb-eb")
    }
    
    func test_sbcb() {
        setupTest("sbcb")
    }
    
    func test_sbcix() {
        setupTest("sbcix")
    }
    
    func test_sbciy() {
        setupTest("sbciy")
    }
    
    func test_sbcz() {
        setupTest("sbcz")
    }
    
    func test_sbczx() {
        setupTest("sbczx")
    }
    
    func test_sbxb() {
        setupTest("sbxb")
    }
    
    func test_secn() {
        setupTest("secn")
    }
    
    func test_sedn() {
        setupTest("sedn")
    }
    
    func test_sein() {
        setupTest("sein")
    }
    
    func test_shaay() {
        setupTest("shaay")
    }
    
    func test_shaiy() {
        setupTest("shaiy")
    }
    
    func test_shsay() {
        setupTest("shsay")
    }
    
    func test_shxay() {
        setupTest("shxay")
    }
    
    func test_shyax() {
        setupTest("shyax")
    }
    
    func test_staa() {
        setupTest("staa")
    }
    
    func test_staax() {
        setupTest("staax")
    }
    
    func test_staay() {
        setupTest("staay")
    }
    
    func test_staix() {
        setupTest("staix")
    }
    
    func test_staiy() {
        setupTest("staiy")
    }
    
    func test_start() {
        setupTest("start")
    }
    
    func test_staz() {
        setupTest("staz")
    }
    
    func test_stazx() {
        setupTest("stazx")
    }
    
    func test_stxa() {
        setupTest("stxa")
    }
    
    func test_stxz() {
        setupTest("stxz")
    }
    
    func test_stxzy() {
        setupTest("stxzy")
    }
    
    func test_stya() {
        setupTest("stya")
    }
    
    func test_styz() {
        setupTest("styz")
    }
    
    func test_styzx() {
        setupTest("styzx")
    }
    
    func test_taxn() {
        setupTest("taxn")
    }
    
    func test_tayn() {
        setupTest("tayn")
    }
    
    func test_trap1() {
        setupTest("trap1")
    }
    
    func test_trap10() {
        setupTest("trap10")
    }
    
    func test_trap11() {
        setupTest("trap11")
    }
    
    func test_trap12() {
        setupTest("trap12")
    }
    
    func test_trap13() {
        setupTest("trap13")
    }
    
    func test_trap14() {
        setupTest("trap14")
    }
    
    func test_trap15() {
        setupTest("trap15")
    }
    
    func test_trap16() {
        setupTest("trap16")
    }
    
    func test_trap17() {
        setupTest("trap17")
    }
    
    func test_trap2() {
        setupTest("trap2")
    }
    
    func test_trap3() {
        setupTest("trap3")
    }
    
    func test_trap4() {
        setupTest("trap4")
    }
    
    func test_trap5() {
        setupTest("trap5")
    }
    
    func test_trap6() {
        setupTest("trap6")
    }
    
    func test_trap7() {
        setupTest("trap7")
    }
    
    func test_trap8() {
        setupTest("trap8")
    }
    
    func test_trap9() {
        setupTest("trap9")
    }
    
    func test_tsxn() {
        setupTest("tsxn")
    }
    
    func test_txan() {
        setupTest("txan")
    }
    
    func test_txsn() {
        setupTest("txsn")
    }
    
    func test_tyan() {
        setupTest("tyan")
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
    
    func C64DidCrash(c64: C64) {
        XCTAssert(false, "Crash")
        expectation.fulfill()
    }
    
    func C64VideoFrameReady(c64: C64) {
        
    }
    
}
