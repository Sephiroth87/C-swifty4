//
//  VIC.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 10/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

import Foundation

public struct VICConfiguration {

    public let resolution: (width: Int, height: Int)
    public let safeArea: (top: Int, left: Int, bottom: Int, right: Int)
    fileprivate let vblankLines: (first: UInt16, last: UInt16)
    fileprivate let topLine: UInt16
    internal let totalLines: UInt16
    fileprivate let xLimits: (first: UInt16, last: UInt16)
    fileprivate let visibleX: (first: UInt16, last: UInt16)
    internal let cyclesPerRaster: UInt8
    fileprivate let lastDrawCycle: UInt8
    
    static public let pal = VICConfiguration(resolution: (width: 403, height: 284),
                                             safeArea: (top: 18, left: 29, bottom: 0, right: 0),
                                             vblankLines: (first: 300, last: 15),
                                             topLine: 0,
                                             totalLines: 312,
                                             xLimits: (first: 404, last: 504),
                                             visibleX: (first: 480, last: 380),
                                             cyclesPerRaster: 63,
                                             lastDrawCycle: 63)
    static public let palDebug = VICConfiguration(resolution: (width: 504, height: 312),
                                                  safeArea: (top: 0, left: 0, bottom: 0, right: 0),
                                                  vblankLines: (first: 312, last: 0),
                                                  topLine: 0,
                                                  totalLines: 312,
                                                  xLimits: (first: 404, last: 504),
                                                  visibleX: (first: 404, last: 504),
                                                  cyclesPerRaster: 63,
                                                  lastDrawCycle: 63)
    static public let ntsc = VICConfiguration(resolution: (width: 418, height: 235),
                                              safeArea: (top: 0, left: 0, bottom: 0, right: 0),
                                              vblankLines: (first: 13, last: 40),
                                              topLine: 27,
                                              totalLines: 263,
                                              xLimits: (first: 412, last: 512),
                                              visibleX: (first: 489, last: 396),
                                              cyclesPerRaster: 65,
                                              lastDrawCycle: 64) // According to vic-ii.txt by Christian Bauer, in the 6567R8 the X coordinate doesn't increase for one cycle, not really explain why

}

private struct VICPipeline: BinaryConvertible {
    
    fileprivate var graphicsData: UInt8 = 0
    fileprivate var graphicsVideoMatrix: UInt8 = 0
    fileprivate var graphicsColorLine: UInt8 = 0
    fileprivate var mainBorder = false
    fileprivate var verticalBorder = false
    fileprivate var initialRasterX: UInt16 = 0

    static func extract(_ binaryDump: BinaryDump) -> VICPipeline {
        return VICPipeline(graphicsData: binaryDump.next(), graphicsVideoMatrix: binaryDump.next(), graphicsColorLine: binaryDump.next(), mainBorder: binaryDump.next(), verticalBorder: binaryDump.next(), initialRasterX: binaryDump.next())
    }
    
}

internal struct VICState: ComponentState {
    
    //MARK: Memory
    fileprivate var ioMemory: [UInt8] = [UInt8](repeating: 0, count: 64)
    fileprivate var videoMatrix: [UInt8] = [UInt8](repeating: 0, count: 40)
    fileprivate var colorLine: [UInt8] = [UInt8](repeating: 0, count: 40)
    fileprivate var mp: UInt8 = 0 // Sprite Pointer
    fileprivate var screenBuffer = UnsafeMutableBufferPointer<UInt32>(start: nil, count: 0)
    //MARK: -
    
    fileprivate var currentCycle: UInt8 = 1
    fileprivate var currentLine: UInt16 = 0
    
    //MARK: Registers
    fileprivate var m_x: [UInt16] = [UInt16](repeating: 0, count: 8) // X Coordinate Sprite
    fileprivate var m_y: [UInt8] = [UInt8](repeating: 0, count: 8) // Y Coordinate Sprite
    fileprivate var yScroll: UInt8 = 0 // Y Scroll
    fileprivate var rsel = true // (Rows selection)?
    fileprivate var den = true // Display Enable
    fileprivate var bmm = false // Bit Map Mode
    fileprivate var ecm = false // Extended Color Mode
    fileprivate var raster: UInt16 = 0 // Raster Counter
    fileprivate var me: UInt8 = 0 // Sprite Enabled
    fileprivate var csel = true // (Columns selection)?
    fileprivate var mcm = false // Multi Color Mode
    fileprivate var mye: UInt8 = 0 // Sprite Y Expansion
    fileprivate var vm: UInt8 = 0 // Video matrix base address
    fileprivate var cb: UInt8 = 0 // Character base address
    fileprivate var ir: UInt8 = 0 // Interrupt register
    fileprivate var ier: UInt8 = 0 // Interrupt enable register
    fileprivate var ec: UInt8 = 0 // Border Color
    fileprivate var mdp: UInt8 = 0 // Sprite data priority
    fileprivate var mmc: UInt8 = 0 // Sprite Multicolor
    fileprivate var mxe: UInt8 = 0 // Sprite X expansion
    fileprivate var mm: UInt8 = 0 // Sprite-sprite collision
    fileprivate var md: UInt8 = 0 // Sprite-data collision
    fileprivate var b0c: UInt8 = 0 // Background Color 0
    fileprivate var b1c: UInt8 = 0 // Background Color 1
    fileprivate var b2c: UInt8 = 0 // Background Color 2
    fileprivate var b3c: UInt8 = 0 // Background Color 3
    fileprivate var mm0: UInt8 = 0 // Sprite Multicolor 0
    fileprivate var mm1: UInt8 = 0 // Sprite Multicolor 1
    fileprivate var m_c: [UInt8] = [UInt8](repeating: 0, count: 8) // Color Sprite
    //MARK: -
    
    //MARK: Internal Registers
    fileprivate var vc: UInt16 = 0
    fileprivate var vcbase: UInt16 = 0
    fileprivate var rc: UInt8 = 0
    fileprivate var vmli: UInt16 = 0
    fileprivate var displayState = false
    fileprivate var rasterX: UInt16 = 0
    fileprivate var rasterInterruptLine: UInt16 = 0
    fileprivate var ref: UInt8 = 0
    fileprivate var mc: [UInt8] = [UInt8](repeating: 0, count: 8)
    fileprivate var mcbase: [UInt8] = [UInt8](repeating: 0, count: 8)
    fileprivate var yExpansion: [Bool] = [Bool](repeating: true, count: 8)
    //MARK: -
    
    //MARK: Pipeline
    fileprivate var pipe = VICPipeline()
    fileprivate var nextPipe = VICPipeline()
    //MARK: -
    
    //MARK: Bus
    fileprivate var addressBus: UInt16 = 0
    fileprivate var dataBus: UInt8 = 0
    //MARK: -
    
    //MARK: Helpers
    fileprivate var memoryBankAddress: UInt16 = 0
    fileprivate var bufferPosition: Int = 0
    fileprivate var badLinesEnabled = false
    fileprivate var isBadLine = false
    fileprivate var baPin = true
    fileprivate var currentSprite: UInt8 = 3
    fileprivate var spriteDma: [Bool] = [Bool](repeating: false, count: 8)
    fileprivate var spriteDisplay: [Bool] = [Bool](repeating: false, count: 8)
    fileprivate var anySpriteDisplaying = false
    fileprivate var spriteSequencerData: [UInt32] = [UInt32](repeating: 0, count: 8)
    fileprivate var spriteShiftRegisterCount: [Int] = [Int](repeating: 0, count: 8)
    fileprivate var graphicsShiftRegister: UInt8 = 0
    //MARK: -
    
    static func extract(_ binaryDump: BinaryDump) -> VICState {
        //TODO: this will cause the next 2 frames to be skipped, as the actual buffers are in VIC, figure this later
        //      Good enough for now
        let screenBuffer = UnsafeMutableBufferPointer<UInt32>(start: calloc(512 * 512, MemoryLayout<UInt32>.size).assumingMemoryBound(to: UInt32.self), count: 512 * 512)
        return VICState(ioMemory: binaryDump.next(64), videoMatrix: binaryDump.next(40), colorLine: binaryDump.next(40), mp: binaryDump.next(), screenBuffer: screenBuffer, currentCycle: binaryDump.next(), currentLine: binaryDump.next(), m_x: binaryDump.next(8), m_y: binaryDump.next(8), yScroll: binaryDump.next(), rsel: binaryDump.next(), den: binaryDump.next(), bmm: binaryDump.next(), ecm: binaryDump.next(), raster: binaryDump.next(), me: binaryDump.next(), csel:binaryDump.next(), mcm: binaryDump.next(), mye: binaryDump.next(), vm: binaryDump.next(), cb: binaryDump.next(), ir: binaryDump.next(), ier: binaryDump.next(), ec: binaryDump.next(), mdp: binaryDump.next(), mmc: binaryDump.next(), mxe: binaryDump.next(), mm: binaryDump.next(), md: binaryDump.next(), b0c: binaryDump.next(), b1c: binaryDump.next(), b2c: binaryDump.next(), b3c: binaryDump.next(), mm0: binaryDump.next(), mm1: binaryDump.next(), m_c: binaryDump.next(8), vc: binaryDump.next(), vcbase: binaryDump.next(), rc: binaryDump.next(), vmli: binaryDump.next(), displayState: binaryDump.next(), rasterX: binaryDump.next(), rasterInterruptLine: binaryDump.next(), ref: binaryDump.next(), mc: binaryDump.next(8), mcbase: binaryDump.next(8), yExpansion: binaryDump.next(8), pipe: binaryDump.next(), nextPipe: binaryDump.next(), addressBus: binaryDump.next(), dataBus: binaryDump.next(), memoryBankAddress: binaryDump.next(), bufferPosition: binaryDump.next(), badLinesEnabled: binaryDump.next(), isBadLine: binaryDump.next(), baPin: binaryDump.next(), currentSprite: binaryDump.next(), spriteDma: binaryDump.next(8), spriteDisplay: binaryDump.next(8), anySpriteDisplaying: binaryDump.next(), spriteSequencerData: binaryDump.next(8), spriteShiftRegisterCount: binaryDump.next(8), graphicsShiftRegister: binaryDump.next())
    }
    
}

final internal class VIC: Component, LineComponent {

    internal let configuration: VICConfiguration
    internal var state = VICState()
    
    internal var memory: C64Memory!
    internal var irqLine: Line!
    internal var rdyLine: Line!
 
    private let screenBuffer1 = UnsafeMutableBufferPointer<UInt32>(start: calloc(512 * 512, MemoryLayout<UInt32>.size).assumingMemoryBound(to: UInt32.self), count: 512 * 512)
    private let screenBuffer2 = UnsafeMutableBufferPointer<UInt32>(start: calloc(512 * 512, MemoryLayout<UInt32>.size).assumingMemoryBound(to: UInt32.self), count: 512 * 512)
    internal var screenBuffer: UnsafeMutablePointer<UInt32> {
        get {
            return (state.screenBuffer.baseAddress == screenBuffer1.baseAddress ? screenBuffer2.baseAddress : screenBuffer1.baseAddress)!
        }
    }

    private var borderComparison = (top: UInt16(51), left: UInt16(24), bottom: UInt16(251), right: UInt16(344)) // Default value (RSEL = 1, CSEL = 1)

    private let colors: [UInt32] = [
        UInt32(truncatingIfNeeded: (0xFF101010 as UInt64)),
        UInt32(truncatingIfNeeded: (0xFFFFFFFF as UInt64)),
        UInt32(truncatingIfNeeded: (0xFF4040E0 as UInt64)),
        UInt32(truncatingIfNeeded: (0xFFFFFF60 as UInt64)),
        UInt32(truncatingIfNeeded: (0xFFE060E0 as UInt64)),
        UInt32(truncatingIfNeeded: (0xFF40E040 as UInt64)),
        UInt32(truncatingIfNeeded: (0xFFE04040 as UInt64)),
        UInt32(truncatingIfNeeded: (0xFF40FFFF as UInt64)),
        UInt32(truncatingIfNeeded: (0xFF40A0E0 as UInt64)),
        UInt32(truncatingIfNeeded: (0xFF48749C as UInt64)),
        UInt32(truncatingIfNeeded: (0xFFA0A0FF as UInt64)),
        UInt32(truncatingIfNeeded: (0xFF545454 as UInt64)),
        UInt32(truncatingIfNeeded: (0xFF888888 as UInt64)),
        UInt32(truncatingIfNeeded: (0xFFA0FFA0 as UInt64)),
        UInt32(truncatingIfNeeded: (0xFFFFA0A0 as UInt64)),
        UInt32(truncatingIfNeeded: (0xFFC0C0C0 as UInt64)),
    ]
    
    //MARK: LineComponent
    func pin(_ line: Line) -> Bool {
        if line === irqLine {
            return state.ir & 0x80 == 0
        } else if line === rdyLine {
            return state.baPin
        }
        return false
    }
    //MARK: -
    
    init(configuration: VICConfiguration) {
        self.configuration = configuration
        state.screenBuffer = screenBuffer1
        state.raster = configuration.totalLines - 1
        state.rasterX = configuration.xLimits.first - 4
    }
    
    internal func readByte(_ position: UInt8) -> UInt8 {
        switch position {
        case 0x00, 0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E:
            return UInt8(truncatingIfNeeded: state.m_x[Int(position >> 1)])
        case 0x01, 0x03, 0x05, 0x07, 0x09, 0x0B, 0x0D, 0x0F:
            return state.m_y[Int((position - 1) >> 1)]
        case 0x10:
            var value = (state.m_x[0] & 0xFF00) >> 8
            value |= (state.m_x[1] & 0xFF00) >> 7
            value |= (state.m_x[2] & 0xFF00) >> 6
            value |= (state.m_x[3] & 0xFF00) >> 5
            value |= (state.m_x[4] & 0xFF00) >> 4
            value |= (state.m_x[5] & 0xFF00) >> 3
            value |= (state.m_x[6] & 0xFF00) >> 2
            value |= (state.m_x[7] & 0xFF00) >> 1
            return UInt8(truncatingIfNeeded: value)
        case 0x11:
            return (state.yScroll & 0x07) | (state.rsel ? 0x08 : 0) | (state.den ? 0x10 : 0) | (state.bmm ? 0x20 : 0) | (state.ecm ? 0x40 : 0) | UInt8((state.raster & 0x100) >> 1)
        case 0x12:
            return UInt8(truncatingIfNeeded: state.raster)
        case 0x15:
            return state.me
        case 0x16:
            return (state.csel ? 0x08 : 0) | (state.mcm ? 0x10 : 0) | 0xC0 //TODO: missing bit registers
        case 0x17:
            return state.mye
        case 0x18:
            return state.vm << 4 | state.cb << 1 | 0x01
        case 0x19:
            return state.ir | 0x70
        case 0x1A:
            return state.ier | 0xF0
        case 0x1B:
            return state.mdp
        case 0x1C:
            return state.mmc
        case 0x1D:
            return state.mxe
        case 0x1E:
            let value = state.mm
            state.mm = 0
            return value
        case 0x1F:
            let value = state.md
            state.md = 0
            return value
        case 0x20:
            return state.ec | 0xF0
        case 0x21:
            return state.b0c
        case 0x22:
            return state.b1c
        case 0x23:
            return state.b2c
        case 0x24:
            return state.b3c
        case 0x25:
            return state.mm0
        case 0x26:
            return state.mm1
        case 0x27...0x2E:
            return state.m_c[Int(position - 0x27)]
        default:
            return 0
        }
    }
    
    internal func writeByte(_ position:UInt8, byte: UInt8) {
        switch position {
        case 0x00, 0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E:
            state.m_x[Int(position >> 1)] = (state.m_x[Int(position >> 1)] & 0xFF00) | UInt16(byte)
        case 0x01, 0x03, 0x05, 0x07, 0x09, 0x0B, 0x0D, 0x0F:
            state.m_y[Int((position - 1) >> 1)] = byte
        case 0x10:
            state.m_x[0] = UInt16(byte & 0x01) << 8 | (state.m_x[0] & 0x00FF)
            state.m_x[1] = UInt16(byte & 0x02) << 7 | (state.m_x[1] & 0x00FF)
            state.m_x[2] = UInt16(byte & 0x04) << 6 | (state.m_x[2] & 0x00FF)
            state.m_x[3] = UInt16(byte & 0x08) << 5 | (state.m_x[3] & 0x00FF)
            state.m_x[4] = UInt16(byte & 0x10) << 4 | (state.m_x[4] & 0x00FF)
            state.m_x[5] = UInt16(byte & 0x20) << 3 | (state.m_x[5] & 0x00FF)
            state.m_x[6] = UInt16(byte & 0x40) << 2 | (state.m_x[6] & 0x00FF)
            state.m_x[7] = UInt16(byte & 0x80) << 1 | (state.m_x[7] & 0x00FF)
        case 0x11:
            state.yScroll = byte & 0x07
            state.rsel = byte & 0x08 != 0
            borderComparison.top = state.rsel ? 51 : 55
            borderComparison.bottom = state.rsel ? 251 : 247
            state.den = byte & 0x10 != 0
            state.bmm = byte & 0x20 != 0
            state.ecm = byte & 0x40 != 0
            if case let newRasterInterruptLine = UInt16(byte & 0x80) << 1 | (state.rasterInterruptLine & 0x00FF), newRasterInterruptLine != state.rasterInterruptLine {
                state.rasterInterruptLine = newRasterInterruptLine
                if state.raster == state.rasterInterruptLine {
                    state.ir |= 0x01
                    updateIRQLine()
                }
            }
            if state.raster == 0x30 && state.den {
                state.badLinesEnabled = true
            }
        case 0x12:
            if case let newRasterInterruptLine = (state.rasterInterruptLine & 0xFF00) | UInt16(byte), newRasterInterruptLine != state.rasterInterruptLine {
                state.rasterInterruptLine = newRasterInterruptLine
                if state.raster == state.rasterInterruptLine {
                    state.ir |= 0x01
                    updateIRQLine()
                }
            }
        case 0x15:
            state.me = byte
        case 0x16:
            state.csel = byte & 0x08 != 0
            borderComparison.left = state.csel ? 24 : 31
            borderComparison.right = state.csel ? 344 : 335
            state.mcm = byte & 0x10 != 0
        case 0x17:
            state.mye = byte
        case 0x18:
            state.cb = (byte & 0x0E) >> 1
            state.vm = (byte & 0xF0) >> 4
        case 0x19:
            state.ir = (state.ir & 0x80) | (state.ir & (~byte & 0x0F))
            updateIRQLine()
        case 0x1A:
            state.ier = byte & 0x0F
        case 0x1B:
            state.mdp = byte
        case 0x1C:
            state.mmc = byte
        case 0x1D:
            state.mxe = byte
        case 0x1E:
            state.mm = byte
        case 0x1F:
            state.md = byte
        case 0x20:
            state.ec = byte & 0x0F
        case 0x21:
            state.b0c = byte & 0x0F
        case 0x22:
            state.b1c = byte & 0x0F
        case 0x23:
            state.b2c = byte & 0x0F
        case 0x24:
            state.b3c = byte & 0x0F
        case 0x25:
            state.mm0 = byte & 0x0F
        case 0x26:
            state.mm1 = byte & 0x0F
        case 0x27...0x2E:
            state.m_c[Int(position - 0x27)] = byte & 0x0F
        default:
            break
        }
        state.ioMemory[Int(position)] = byte
    }
    
    internal func setMemoryBank(_ bankNumber: UInt8) {
        state.memoryBankAddress = UInt16(~bankNumber & 0x3) << 14
    }

    private func memoryAccess(_ position: UInt16) -> UInt8 {
        state.addressBus = state.memoryBankAddress &+ position
        if state.addressBus & 0x7000 == 0x1000 { // address in 0x1000...0x1FFF or 0x9000...0x9FFF
            // Read from character ROM
            state.dataBus = memory.readROMByte(0xC000 &+ position)
        } else {
            state.dataBus = memory.readRAMByte(state.addressBus)
        }
        return state.dataBus
    }
    
    private func updateIRQLine() {
        let value = state.ir & 0x80
        if (state.ir & state.ier) & 0x0F != 0 {
            state.ir |= 0x80
        } else {
            state.ir &= 0x7F
        }
        if value != state.ir & 0x80 {
            irqLine.update(self)
        }
    }
    
    private func setBAPin(_ value: Bool) {
        if value != state.baPin {
            state.baPin = value
            rdyLine.update(self)
        }
    }

    private func endOfRasterline() {
        if state.raster == configuration.totalLines - 1 {
            state.bufferPosition = 0
            state.screenBuffer = state.screenBuffer.baseAddress == screenBuffer1.baseAddress ? screenBuffer2 : screenBuffer1
        }
    }
    
    private func updateAnySpriteDisplaying() {
        if state.spriteDisplay.index(of: true) == nil && state.spriteDma.index(of: true) == nil {
            state.anySpriteDisplaying = false
        } else {
            state.anySpriteDisplaying = true
        }
    }

    internal func cycle() {
        if state.currentCycle == 1 {
            state.raster += 1
            if state.raster == configuration.totalLines {
                state.raster = 0
            }
            if state.raster == 0x30 {
                state.badLinesEnabled = state.den
            }
        }
        // Initial cycle operations
        if state.raster >= 0x30 && state.raster <= 0xF7 {
            if state.currentCycle == 1 {
                state.isBadLine = false
            }
            if state.raster == 0x30 && state.den {
                state.badLinesEnabled = true
            }
            if UInt8(state.raster) & 7 == state.yScroll && state.badLinesEnabled {
                state.isBadLine = true
                state.displayState = true
            }
        }
        switch state.currentCycle {
        case 1:
            if state.raster == 0 {
                state.vcbase = 0
                state.ref = 0xFF
            }
        case 14:
            state.vc = state.vcbase
            state.vmli = 0
            if state.isBadLine {
                state.rc = 0
            }
            rAccess()
        case 11:
            setBAPin(true)
            fallthrough
        case 12...15:
            rAccess()
        case 58:
            if state.rc == 7 {
                state.displayState = false
                state.vcbase = state.vc
            }
            if state.displayState {
                state.rc = (state.rc + 1) & 7
            }
        default:
            break
        }
        let cyclesPerRaster = configuration.cyclesPerRaster
        if state.currentCycle <= configuration.lastDrawCycle {
            if state.currentCycle >= 18 && state.currentCycle <= 57 {
                state.graphicsShiftRegister = state.pipe.graphicsData
            }
            draw()
            state.pipe = state.nextPipe
        }
        switch state.currentCycle {
        case 1, 3, 5, 7, 9:
            pAccess()
            if state.spriteDma[Int(state.currentSprite)] {
                sAccess(0)
            }
        case 2, 4, 6, 8, 10:
            if state.spriteDma[Int(state.currentSprite)] {
                sAccess(1)
                sAccess(2)
            }
            state.currentSprite = (state.currentSprite + 1) & 7
        case 15:
            cAccess()
        case 16:
            gAccess()
            for i in 0...7 {
                if state.yExpansion[i] {
                    //TODO: Some stuff here if yExpansion vas cleared in cycle 15 (VIC addendum)
                    state.mcbase[i] = state.mc[i]
                }
                if state.mcbase[i] == 63 {
                    state.spriteDma[i] = false
                }
            }
            cAccess()
        case 17...54:
            gAccess()
            cAccess()
        case 55:
            gAccess()
        default:
            break
        }
        switch state.currentCycle {
        case cyclesPerRaster - 8:
            for i in 0...7 {
                if state.mye & UInt8(1 << i) != 0 {
                    state.yExpansion[i] = !state.yExpansion[i]
                }
            }
            fallthrough
        case cyclesPerRaster - 7:
            for i in 0...7 {
                if state.me & UInt8(1 << i) != 0 && state.m_y[i] == UInt8(truncatingIfNeeded: state.raster) {
                    state.spriteDma[i] = true
                    state.mcbase[i] = 0
                    if state.mye & UInt8(1 << i) != 0 {
                        state.yExpansion[i] = false
                    }
                }
            }
            updateAnySpriteDisplaying()
        case cyclesPerRaster - 5:
            for i in 0...7 {
                state.mc[i] = state.mcbase[i]
                if state.spriteDma[i] {
                    if state.me & UInt8(1 << i) != 0 && state.m_y[i] == UInt8(truncatingIfNeeded: state.raster) {
                        state.spriteDisplay[i] = true
                    }
                } else {
                    state.spriteDisplay[i] = false
                }
            }
            updateAnySpriteDisplaying()
            fallthrough
        case cyclesPerRaster - 3, cyclesPerRaster - 1:
            pAccess()
            if state.spriteDma[Int(state.currentSprite)] {
                sAccess(0)
            }
        case cyclesPerRaster - 4, cyclesPerRaster - 2, cyclesPerRaster:
            if state.spriteDma[Int(state.currentSprite)] {
                sAccess(1)
                sAccess(2)
            }
            state.currentSprite = (state.currentSprite + 1) & 7
        default:
            break
        }
        if state.currentCycle >= 12 && state.currentCycle <= 54 {
            if state.isBadLine {
                setBAPin(false)
            }
        } else if state.anySpriteDisplaying && (state.currentCycle <= 10 || state.currentCycle >= cyclesPerRaster - 8) {
            let shiftedCycle = (state.currentCycle - 1 + 9) % configuration.cyclesPerRaster
            let firstSprite = max(0, (Int(shiftedCycle) - 3) / 2)
            let lastSprite = min(7, Int(shiftedCycle) / 2)
            let range = firstSprite...lastSprite
            setBAPin(!(state.spriteDma[range].reduce(false, or)))
        } else {
            setBAPin(true)
        }
        if state.rasterInterruptLine == state.raster {
            if (state.raster == 0 && state.currentCycle == 2) || state.currentCycle == 1 {
                state.ir |= 0x01
                updateIRQLine()
            }
        }
        if state.currentCycle == cyclesPerRaster {
            endOfRasterline()
            state.currentCycle = 0
        }
        state.currentCycle += 1
    }
    
    // Video matrix access
    private func cAccess() {
        if state.isBadLine {
            state.videoMatrix[Int(state.vmli)] = memoryAccess(UInt16(state.vm) << 10 &+ state.vc)
            state.colorLine[Int(state.vmli)] = memory.readColorRAMByte(state.vc) & 0x0F
        }
    }
    
    // Graphic access
    private func gAccess() {
        if state.displayState {
            if state.bmm {
                state.nextPipe.graphicsData = memoryAccess(UInt16(state.cb & 0x04) << 11 | state.vc << 3 | UInt16(state.rc))
            } else {
                state.nextPipe.graphicsData = memoryAccess(UInt16(state.cb) << 11 | (UInt16(state.videoMatrix[Int(state.vmli)]) & (state.ecm ? 0x3F : 0xFF)) << 3 | UInt16(state.rc))
            }
            state.nextPipe.graphicsVideoMatrix = state.videoMatrix[Int(state.vmli)]
            state.nextPipe.graphicsColorLine = state.colorLine[Int(state.vmli)]
            state.vc = (state.vc + 1) & 0x3FF
            state.vmli = (state.vmli + 1) & 0x3F
        } else {
            state.nextPipe.graphicsData = state.ecm ? memoryAccess(0x39FF) : memoryAccess(0x3FFF)
            state.nextPipe.graphicsVideoMatrix = 0
            state.nextPipe.graphicsColorLine = 0
        }
    }
    
    // Sprite data pointers access
    private func pAccess() {
        state.mp = memoryAccess(UInt16(state.vm) << 10 | 0x03F8 | UInt16(state.currentSprite))
    }
    
    // Sprite data access
    private func sAccess(_ accessNumber: Int) {
        let data = memoryAccess(UInt16(state.mp) << 6 | UInt16(state.mc[Int(state.currentSprite)]))
        state.spriteSequencerData[Int(state.currentSprite)] |= UInt32(data) << UInt32(8 * (2 - accessNumber))
        state.mc[Int(state.currentSprite)] = (state.mc[Int(state.currentSprite)] + 1) & 0x3F
    }
    
    // DRAM refresh
    private func rAccess() {
        _ = memoryAccess(0x3F00 | UInt16(state.ref))
        state.ref = state.ref &- 1
    }

    // Draw 8 pixels
    private func draw() {
        // vic-ii.txt says Y coord is only checked two times per raster [3.9], but in practice it looks it's checked every cycle. this fixes all dentest tests
        if state.raster == borderComparison.bottom {
            state.nextPipe.verticalBorder = true
        } else if state.raster == borderComparison.top && state.den {
            state.nextPipe.verticalBorder = false
        }
        state.nextPipe.initialRasterX = state.rasterX
        for i in 0...7 {
            if (state.rasterX >= configuration.visibleX.first || state.rasterX < configuration.visibleX.last - 1) &&
                (state.raster > configuration.vblankLines.last || state.raster < configuration.vblankLines.first) {
                if state.rasterX == borderComparison.right {
                    state.nextPipe.mainBorder = true
                } else if state.rasterX == borderComparison.left {
                    if !state.nextPipe.verticalBorder {
                        state.nextPipe.mainBorder = false
                    }
                }
                var foregroundPixel: Int? = nil
                if state.bmm {
                    if state.mcm {
                        switch (state.graphicsShiftRegister & 0xC0) >> 6 {
                        case 0:
                            state.screenBuffer[state.bufferPosition] = colors[Int(state.b0c)]
                        case 1:
                            state.screenBuffer[state.bufferPosition] = colors[Int((state.pipe.graphicsVideoMatrix & 0xF0) >> 4)]
                        case 2:
                            foregroundPixel = Int(state.pipe.graphicsVideoMatrix & 0x0F)
                        case 3:
                            foregroundPixel = Int(state.pipe.graphicsColorLine)
                        default:
                            break
                        }
                        if i % 2 == 1 {
                            state.graphicsShiftRegister <<= 2
                        }
                    } else {
                        if state.graphicsShiftRegister >> 7 == 0 {
                            state.screenBuffer[state.bufferPosition] = colors[Int(state.pipe.graphicsVideoMatrix & 0x0F)]
                        } else {
                            foregroundPixel = Int((state.pipe.graphicsVideoMatrix & 0xF0) >> 4)
                        }
                        state.graphicsShiftRegister <<= 1
                    }
                } else if (!state.mcm && !state.bmm) || (state.mcm && state.pipe.graphicsColorLine & 0x08 == 0) {
                    if state.graphicsShiftRegister >> 7 != 0 {
                        foregroundPixel = Int(state.pipe.graphicsColorLine)
                    } else {
                        if state.ecm {
                            switch (state.pipe.graphicsVideoMatrix & 0xC0) >> 6 {
                            case 0:
                                state.screenBuffer[state.bufferPosition] = colors[Int(state.b0c)]
                            case 1:
                                state.screenBuffer[state.bufferPosition] = colors[Int(state.b1c)]
                            case 2:
                                state.screenBuffer[state.bufferPosition] = colors[Int(state.b2c)]
                            case 3:
                                state.screenBuffer[state.bufferPosition] = colors[Int(state.b3c)]
                            default:
                                break
                            }
                        } else {
                            state.screenBuffer[state.bufferPosition] = colors[Int(state.b0c)]
                        }
                    }
                    state.graphicsShiftRegister <<= 1
                } else {
                    switch (state.graphicsShiftRegister & 0xC0) >> 6 {
                    case 0:
                        state.screenBuffer[state.bufferPosition] = colors[Int(state.b0c)]
                    case 1:
                        state.screenBuffer[state.bufferPosition] = colors[Int(state.b1c)]
                    case 2:
                        foregroundPixel = Int(state.b2c)
                    case 3:
                        foregroundPixel = Int(state.pipe.graphicsColorLine) & 0x07
                    default:
                        break
                    }
                    if i % 2 == 1 {
                        state.graphicsShiftRegister <<= 2
                    }
                }
                if state.anySpriteDisplaying {
                    var topSprite: Int? = nil
                    var spritePixel: Int? = nil
                    var spriteCollisions: UInt8 = 0
                    for spriteIndex in (0...7).reversed() {
                        if state.spriteDisplay[spriteIndex] {
                            let previousCycleRasterX = state.rasterX >= 8 ? state.rasterX - 8 : configuration.xLimits.last + state.rasterX - 8
                            if state.m_x[spriteIndex] == previousCycleRasterX {
                                state.spriteShiftRegisterCount[spriteIndex] = 24
                            }
                            if state.spriteShiftRegisterCount[spriteIndex] > 0 {
                                let xExpansion = state.mxe & UInt8(1 << spriteIndex) != 0
                                var currentSpritePixel: Int? = nil
                                if state.mmc & UInt8(1 << spriteIndex) != 0 {
                                    switch (state.spriteSequencerData[spriteIndex] >> 22) & 0x03 {
                                    case 1:
                                        currentSpritePixel = Int(state.mm0)
                                    case 2:
                                        currentSpritePixel = Int(state.m_c[spriteIndex])
                                    case 3:
                                        currentSpritePixel = Int(state.mm1)
                                    default:
                                        break
                                    }
                                    if (!xExpansion && i % 2 == 1) || (xExpansion && i % 4 == 3) {
                                        state.spriteSequencerData[spriteIndex] <<= 2
                                        state.spriteShiftRegisterCount[spriteIndex] -= 2
                                    }
                                } else {
                                    if state.spriteSequencerData[spriteIndex] & 0x800000 != 0 {
                                        currentSpritePixel = Int(state.m_c[spriteIndex])
                                    }
                                    if !xExpansion || (xExpansion && i % 2 == 1) {
                                        state.spriteSequencerData[spriteIndex] <<= 1
                                        state.spriteShiftRegisterCount[spriteIndex] -= 1
                                    }
                                }
                                if currentSpritePixel != nil {
                                    spriteCollisions |= UInt8(1 << spriteIndex)
                                    spritePixel = currentSpritePixel
                                    topSprite = spriteIndex
                                }
                            }
                        }
                    }
                    if spriteCollisions > 0 && (spriteCollisions & (spriteCollisions - 1) != 0) { // Check if more than 2 bits are set
                        state.mm |= spriteCollisions
                        state.ir |= 0x04
                        updateIRQLine()
                    }
                    if spriteCollisions > 0 && foregroundPixel != nil {
                        state.md |= spriteCollisions
                        state.ir |= 0x02
                        updateIRQLine()
                    }
                    if let spritePixel = spritePixel, let topSprite = topSprite, (state.mdp & UInt8(1 << topSprite) == 0 || foregroundPixel == nil) {
                        state.screenBuffer[state.bufferPosition] = colors[spritePixel]
                    } else if let foregroundPixel = foregroundPixel {
                        state.screenBuffer[state.bufferPosition] = colors[foregroundPixel]
                    }
                } else if let foregroundPixel = foregroundPixel {
                    state.screenBuffer[state.bufferPosition] = colors[foregroundPixel]
                }
                
                if state.pipe.mainBorder || state.pipe.verticalBorder {
                    state.screenBuffer[state.bufferPosition] = colors[Int(state.ec)]
                }
                state.bufferPosition += 1
            }
            state.rasterX += 1
            if state.rasterX == configuration.xLimits.last {
                state.rasterX = 0
            }
        }
    }
    
}
