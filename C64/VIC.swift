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
    
    //MARK: Registers
    fileprivate var m_x = FixedArray8<UInt16>(repeating: 0) // X Coordinate Sprite
    fileprivate var bmm = false // Bit Map Mode
    fileprivate var ecm = false // Extended Color Mode
    fileprivate var mcm = false // Multi Color Mode
    fileprivate var mxe: UInt8 = 0 // Sprite X expansion
    //MARK: -
    
    fileprivate var graphicsData: UInt8 = 0
    fileprivate var graphicsVideoMatrix: UInt8 = 0
    fileprivate var graphicsColorLine: UInt8 = 0
    fileprivate var mainBorder = false
    fileprivate var verticalBorder = false
    fileprivate var initialRasterX: UInt16 = 0
    fileprivate var xScroll: UInt8 = 0

    static func extract(_ binaryDump: BinaryDump) -> VICPipeline {
        return VICPipeline(m_x: binaryDump.next(), bmm: binaryDump.next(), ecm: binaryDump.next(), mcm: binaryDump.next(), mxe: binaryDump.next(), graphicsData: binaryDump.next(), graphicsVideoMatrix: binaryDump.next(), graphicsColorLine: binaryDump.next(), mainBorder: binaryDump.next(), verticalBorder: binaryDump.next(), initialRasterX: binaryDump.next(), xScroll: binaryDump.next())
    }
    
}

private struct VICColorPipeline: BinaryConvertible {
    
    //MARK: Registers
    fileprivate var ec: UInt8 = 0 // Border Color
    fileprivate var b0c: UInt8 = 0 // Background Color 0
    fileprivate var b1c: UInt8 = 0 // Background Color 1
    fileprivate var b2c: UInt8 = 0 // Background Color 2
    fileprivate var b3c: UInt8 = 0 // Background Color 3
    fileprivate var mm0: UInt8 = 0 // Sprite Multicolor 0
    fileprivate var mm1: UInt8 = 0 // Sprite Multicolor 1
    fileprivate var m_c = FixedArray8<UInt8>(repeating: 0) // Color Sprite
    //MARK: -

    static func extract(_ binaryDump: BinaryDump) -> VICColorPipeline {
        return VICColorPipeline(ec: binaryDump.next(), b0c: binaryDump.next(), b1c: binaryDump.next(), b2c: binaryDump.next(), b3c: binaryDump.next(), mm0: binaryDump.next(), mm1: binaryDump.next(), m_c: binaryDump.next())
    }
    
}

internal struct VICState: ComponentState {
    
    //MARK: Memory
    fileprivate var videoMatrix = FixedArray40<UInt8>(repeating: 0)
    fileprivate var colorLine = FixedArray40<UInt8>(repeating: 0)
    fileprivate var mp: UInt8 = 0 // Sprite Pointer
    fileprivate var screenBuffer = UnsafeMutableBufferPointer<UInt32>(start: nil, count: 0)
    //MARK: -
    
    fileprivate var currentCycle: UInt8 = 1
    fileprivate var currentLine: UInt16 = 0
    
    //MARK: Registers
    fileprivate var m_y = FixedArray8<UInt8>(repeating: 0) // Y Coordinate Sprite
    fileprivate var yScroll: UInt8 = 0 // Y Scroll
    fileprivate var rsel = true // (Rows selection)?
    fileprivate var den = true // Display Enable
    fileprivate var raster: UInt16 = 0 // Raster Counter
    fileprivate var me: UInt8 = 0 // Sprite Enabled
    fileprivate var csel = true // (Columns selection)?
    fileprivate var mye: UInt8 = 0 // Sprite Y Expansion
    fileprivate var vm: UInt8 = 0 // Video matrix base address
    fileprivate var cb: UInt8 = 0 // Character base address
    fileprivate var ir: UInt8 = 0 // Interrupt register
    fileprivate var ier: UInt8 = 0 // Interrupt enable register
    fileprivate var mdp: UInt8 = 0 // Sprite data priority
    fileprivate var mmc: UInt8 = 0 // Sprite Multicolor
    fileprivate var mm: UInt8 = 0 // Sprite-sprite collision
    fileprivate var md: UInt8 = 0 // Sprite-data collision
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
    fileprivate var mc = FixedArray8<UInt8>(repeating: 0)
    fileprivate var mcbase = FixedArray8<UInt8>(repeating: 0)
    fileprivate var yExpansion = FixedArray8<Bool>(repeating: true)
    //MARK: -
    
    //MARK: Pipeline
    fileprivate var pipe = VICPipeline()
    fileprivate var nextPipe = VICPipeline()
    fileprivate var colorPipe = VICColorPipeline()
    fileprivate var nextColorPipe = VICColorPipeline()
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
    fileprivate var baLowCount = 0
    fileprivate var currentSprite: UInt8 = 3
    fileprivate var spriteDma = FixedArray8<Bool>(repeating: false)
    fileprivate var spriteDisplay = FixedArray8<Bool>(repeating: false)
    fileprivate var anySpriteDisplaying = false
    fileprivate var spriteSequencerData = FixedArray8<UInt32>(repeating: 0)
    fileprivate var spriteShiftRegisterCount = FixedArray8<Int>(repeating: 0)
    fileprivate var spriteShiftRegisterPixelsPerShift = FixedArray8<Int>(repeating: 0)
    fileprivate var graphicsShiftRegister: UInt8 = 0
    fileprivate var graphicsShiftRegisterRemainingBits: UInt8 = 0
    fileprivate var graphicsPixelData: UInt8 = 0
    fileprivate var graphicsMulticolorFlipFlop: Bool = false
    //MARK: -
    
    static func extract(_ binaryDump: BinaryDump) -> VICState {
        //TODO: this will cause the next 2 frames to be skipped, as the actual buffers are in VIC, figure this later
        //      Good enough for now
        let screenBuffer = UnsafeMutableBufferPointer<UInt32>(start: calloc(512 * 512, MemoryLayout<UInt32>.size).assumingMemoryBound(to: UInt32.self), count: 512 * 512)
        return VICState(videoMatrix: binaryDump.next(), colorLine: binaryDump.next(), mp: binaryDump.next(), screenBuffer: screenBuffer, currentCycle: binaryDump.next(), currentLine: binaryDump.next(), m_y: binaryDump.next(), yScroll: binaryDump.next(), rsel: binaryDump.next(), den: binaryDump.next(), raster: binaryDump.next(), me: binaryDump.next(), csel:binaryDump.next(), mye: binaryDump.next(), vm: binaryDump.next(), cb: binaryDump.next(), ir: binaryDump.next(), ier: binaryDump.next(), mdp: binaryDump.next(), mmc: binaryDump.next(), mm: binaryDump.next(), md: binaryDump.next(), vc: binaryDump.next(), vcbase: binaryDump.next(), rc: binaryDump.next(), vmli: binaryDump.next(), displayState: binaryDump.next(), rasterX: binaryDump.next(), rasterInterruptLine: binaryDump.next(), ref: binaryDump.next(), mc: binaryDump.next(), mcbase: binaryDump.next(), yExpansion: binaryDump.next(), pipe: binaryDump.next(), nextPipe: binaryDump.next(), colorPipe: binaryDump.next(), nextColorPipe: binaryDump.next(), addressBus: binaryDump.next(), dataBus: binaryDump.next(), memoryBankAddress: binaryDump.next(), bufferPosition: binaryDump.next(), badLinesEnabled: binaryDump.next(), isBadLine: binaryDump.next(), baPin: binaryDump.next(), baLowCount: binaryDump.next(), currentSprite: binaryDump.next(), spriteDma: binaryDump.next(), spriteDisplay: binaryDump.next(), anySpriteDisplaying: binaryDump.next(), spriteSequencerData: binaryDump.next(), spriteShiftRegisterCount: binaryDump.next(), spriteShiftRegisterPixelsPerShift: binaryDump.next(), graphicsShiftRegister: binaryDump.next(), graphicsShiftRegisterRemainingBits: binaryDump.next(), graphicsPixelData: binaryDump.next(), graphicsMulticolorFlipFlop: binaryDump.next())
    }

    var description: String {
        return "🎨 (\(rasterX), \(raster)) - \(currentCycle)"
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
    
    internal var dataBus: UInt8 {
        return state.dataBus
    }
    
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
            return UInt8(truncatingIfNeeded: state.nextPipe.m_x[Int(position >> 1)])
        case 0x01, 0x03, 0x05, 0x07, 0x09, 0x0B, 0x0D, 0x0F:
            return state.m_y[Int((position - 1) >> 1)]
        case 0x10:
            var value = (state.nextPipe.m_x[0] & 0xFF00) >> 8
            value |= (state.nextPipe.m_x[1] & 0xFF00) >> 7
            value |= (state.nextPipe.m_x[2] & 0xFF00) >> 6
            value |= (state.nextPipe.m_x[3] & 0xFF00) >> 5
            value |= (state.nextPipe.m_x[4] & 0xFF00) >> 4
            value |= (state.nextPipe.m_x[5] & 0xFF00) >> 3
            value |= (state.nextPipe.m_x[6] & 0xFF00) >> 2
            value |= (state.nextPipe.m_x[7] & 0xFF00) >> 1
            return UInt8(truncatingIfNeeded: value)
        case 0x11:
            return (state.yScroll & 0x07) | (state.rsel ? 0x08 : 0) | (state.den ? 0x10 : 0) | (state.nextPipe.bmm ? 0x20 : 0) | (state.nextPipe.ecm ? 0x40 : 0) | UInt8((state.raster & 0x100) >> 1)
        case 0x12:
            return UInt8(truncatingIfNeeded: state.raster)
        case 0x15:
            return state.me
        case 0x16:
            return state.nextPipe.xScroll | (state.csel ? 0x08 : 0) | (state.nextPipe.mcm ? 0x10 : 0) | 0xC0
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
            return state.nextPipe.mxe
        case 0x1E:
            let value = state.mm
            state.mm = 0
            return value
        case 0x1F:
            let value = state.md
            state.md = 0
            return value
        case 0x20:
            return state.nextColorPipe.ec | 0xF0
        case 0x21:
            return state.nextColorPipe.b0c
        case 0x22:
            return state.nextColorPipe.b1c
        case 0x23:
            return state.nextColorPipe.b2c
        case 0x24:
            return state.nextColorPipe.b3c
        case 0x25:
            return state.nextColorPipe.mm0
        case 0x26:
            return state.nextColorPipe.mm1
        case 0x27...0x2E:
            return state.nextColorPipe.m_c[Int(position - 0x27)]
        default:
            return 0
        }
    }
    
    internal func writeByte(_ position:UInt8, byte: UInt8) {
        switch position {
        case 0x00, 0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E:
            state.nextPipe.m_x[Int(position >> 1)] = (state.nextPipe.m_x[Int(position >> 1)] & 0xFF00) | UInt16(byte)
        case 0x01, 0x03, 0x05, 0x07, 0x09, 0x0B, 0x0D, 0x0F:
            state.m_y[Int((position - 1) >> 1)] = byte
        case 0x10:
            state.nextPipe.m_x[0] = UInt16(byte & 0x01) << 8 | (state.nextPipe.m_x[0] & 0x00FF)
            state.nextPipe.m_x[1] = UInt16(byte & 0x02) << 7 | (state.nextPipe.m_x[1] & 0x00FF)
            state.nextPipe.m_x[2] = UInt16(byte & 0x04) << 6 | (state.nextPipe.m_x[2] & 0x00FF)
            state.nextPipe.m_x[3] = UInt16(byte & 0x08) << 5 | (state.nextPipe.m_x[3] & 0x00FF)
            state.nextPipe.m_x[4] = UInt16(byte & 0x10) << 4 | (state.nextPipe.m_x[4] & 0x00FF)
            state.nextPipe.m_x[5] = UInt16(byte & 0x20) << 3 | (state.nextPipe.m_x[5] & 0x00FF)
            state.nextPipe.m_x[6] = UInt16(byte & 0x40) << 2 | (state.nextPipe.m_x[6] & 0x00FF)
            state.nextPipe.m_x[7] = UInt16(byte & 0x80) << 1 | (state.nextPipe.m_x[7] & 0x00FF)
        case 0x11:
            state.yScroll = byte & 0x07
            state.rsel = byte & 0x08 != 0
            borderComparison.top = state.rsel ? 51 : 55
            borderComparison.bottom = state.rsel ? 251 : 247
            state.den = byte & 0x10 != 0
            state.nextPipe.bmm = byte & 0x20 != 0
            state.nextPipe.ecm = byte & 0x40 != 0
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
            state.isBadLine = state.badLinesEnabled && state.raster >= 0x30 && state.raster <= 0xF7 && UInt8(state.raster) & 7 == state.yScroll
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
            state.nextPipe.xScroll = byte & 0x07
            state.csel = byte & 0x08 != 0
            borderComparison.left = state.csel ? 24 : 31
            borderComparison.right = state.csel ? 344 : 335
            state.nextPipe.mcm = byte & 0x10 != 0
        case 0x17:
            state.mye = byte
            for i in 0...7 {
                if state.mye & UInt8(1 << i) == 0 {
                    state.yExpansion[i] = true
                }
            }
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
            state.nextPipe.mxe = byte
        case 0x1E:
            state.mm = byte
        case 0x1F:
            state.md = byte
        case 0x20:
            state.nextColorPipe.ec = byte & 0x0F
        case 0x21:
            state.nextColorPipe.b0c = byte & 0x0F
        case 0x22:
            state.nextColorPipe.b1c = byte & 0x0F
        case 0x23:
            state.nextColorPipe.b2c = byte & 0x0F
        case 0x24:
            state.nextColorPipe.b3c = byte & 0x0F
        case 0x25:
            state.nextColorPipe.mm0 = byte & 0x0F
        case 0x26:
            state.nextColorPipe.mm1 = byte & 0x0F
        case 0x27...0x2E:
            state.nextColorPipe.m_c[Int(position - 0x27)] = byte & 0x0F
        default:
            break
        }
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
        if value {
            state.baLowCount = 0
        }
    }

    private func endOfRasterline() {
        if state.raster == configuration.totalLines - 1 {
            state.bufferPosition = 0
            state.screenBuffer = state.screenBuffer.baseAddress == screenBuffer1.baseAddress ? screenBuffer2 : screenBuffer1
        }
    }
    
    private func updateAnySpriteDisplaying() {
        if state.spriteDisplay.firstIndex(of: true) == nil && state.spriteDma.firstIndex(of: true) == nil {
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
            state.isBadLine = state.badLinesEnabled && state.raster >= 0x30 && state.raster <= 0xF7 && UInt8(state.raster) & 7 == state.yScroll
        }
        if !state.baPin {
            state.baLowCount += 1
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
                state.vcbase = state.vc
                if !state.isBadLine {
                    state.displayState = false
                }
            }
            if state.displayState {
                state.rc = (state.rc + 1) & 7
            }
        default:
            break
        }
        let cyclesPerRaster = configuration.cyclesPerRaster
        if state.currentCycle <= configuration.lastDrawCycle {
            draw()
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
            } else {
                iAccess()
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
            iAccess()
        case cyclesPerRaster - 6:
            iAccess()
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
            } else {
                iAccess()
            }
            state.currentSprite = (state.currentSprite + 1) & 7
        default:
            break
        }
        // BMM delay
        state.pipe.bmm = state.nextPipe.bmm
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
        if state.isBadLine {
            state.displayState = true
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
            if state.baLowCount > 2 {
                state.videoMatrix[Int(state.vmli)] = memoryAccess(UInt16(state.vm) << 10 &+ state.vc)
                state.colorLine[Int(state.vmli)] = memory.readColorRAMByte(state.vc) & 0x0F
            } else {
                state.videoMatrix[Int(state.vmli)] = 0xFF
                // This is my interpretation of vic-ii.txt, using low 4 bits of PC, other emulators read ram at PC instead
                // Couldn't find a test to actually check which one is right
                state.colorLine[Int(state.vmli)] = UInt8(truncatingIfNeeded: memory.cpu.state.pc) & 0x0F
            }
        }
    }
    
    // Graphic access
    private func gAccess() {
        if state.displayState {
            if state.nextPipe.bmm || state.pipe.bmm {
                state.nextPipe.graphicsData = memoryAccess(UInt16(state.cb & 0x04) << 11 | state.vc << 3 | UInt16(state.rc))
            } else {
                state.nextPipe.graphicsData = memoryAccess(UInt16(state.cb) << 11 | (UInt16(state.videoMatrix[Int(state.vmli)]) & (state.nextPipe.ecm ? 0x3F : 0xFF)) << 3 | UInt16(state.rc))
            }
            state.nextPipe.graphicsVideoMatrix = state.videoMatrix[Int(state.vmli)]
            state.nextPipe.graphicsColorLine = state.colorLine[Int(state.vmli)]
            state.vc = (state.vc + 1) & 0x3FF
            state.vmli = (state.vmli + 1) & 0x3F
        } else {
            state.nextPipe.graphicsData = state.nextPipe.ecm ? memoryAccess(0x39FF) : memoryAccess(0x3FFF)
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
    
    // Idle access
    private func iAccess() {
        _ = memoryAccess(0x3FFF)
    }

    @inline(never)
    // Draw 8 pixels
    private func draw() {
        // vic-ii.txt says Y coord is only checked two times per raster [3.9], but in practice it looks it's checked every cycle. this fixes all dentest tests
        if state.raster == borderComparison.bottom {
            state.nextPipe.verticalBorder = true
        } else if state.raster == borderComparison.top && state.den {
            state.nextPipe.verticalBorder = false
        }
        state.nextPipe.initialRasterX = state.rasterX
        drawPixel(0)
        // Colors have 1 px delay
        state.colorPipe = state.nextColorPipe
        drawPixel(1)
        drawPixel(2)
        drawPixel(3)
        drawPixel(4)
        drawPixel(5)
        // MXE has a shorter delay (6 px), so handle it separately here...
        state.pipe.mxe = state.nextPipe.mxe
        drawPixel(6)
        if !state.pipe.mcm && state.nextPipe.mcm {
            state.graphicsMulticolorFlipFlop = false
        }
        // MCM delay takes full effect after 7 pixels, more info below
        state.pipe.mcm = state.nextPipe.mcm
        drawPixel(7)
        // BMM delay should happen after gAccess, so transfer nextPipe except BMM (no overhead as it is optimized out)
        let bmm = state.pipe.bmm
        state.pipe = state.nextPipe
        state.pipe.bmm = bmm
    }
    
    // Handling everything in a single function was causing the compiler to generate some weird and much slower code, so split up everything
    // Subfunction are always inlined for performance
    private func drawPixel(_ i: Int) {
        if (state.rasterX >= configuration.visibleX.first || state.rasterX < configuration.visibleX.last - 1) &&
            (state.raster > configuration.vblankLines.last || state.raster < configuration.vblankLines.first) {
            if state.rasterX == borderComparison.right {
                state.nextPipe.mainBorder = true
            } else if state.rasterX == borderComparison.left {
                if !state.nextPipe.verticalBorder {
                    state.nextPipe.mainBorder = false
                }
            }
            if state.currentCycle >= 18 && state.currentCycle <= 57 && i == state.pipe.xScroll {
                state.graphicsShiftRegister = state.pipe.graphicsData
                state.graphicsMulticolorFlipFlop = true
                state.graphicsShiftRegisterRemainingBits = 8
            }
            // Clear any outstanding multicolor bit that shouldn't actually be drawn
            // TODO: VICE doesn't use a counter for this, but doesn't have the same issue, figure out what magic they are doing
            if state.graphicsShiftRegisterRemainingBits == 0 {
                state.graphicsPixelData = 0
            }
            let graphicsPixel = drawGraphicsPixel(i)
            let (spritePixel, topSprite, spriteCollisions) = drawSpritePixel(i)
            if spriteCollisions > 0 && graphicsPixel != nil {
                state.md |= spriteCollisions
                state.ir |= 0x02
                updateIRQLine()
            }
            if let spritePixel = spritePixel, let topSprite = topSprite, (state.mdp & UInt8(1 << topSprite) == 0 || graphicsPixel == nil) {
                state.screenBuffer[state.bufferPosition] = colors[spritePixel]
            } else if let graphicsPixel = graphicsPixel {
                state.screenBuffer[state.bufferPosition] = colors[graphicsPixel]
            }
            if state.pipe.mainBorder {
                state.screenBuffer[state.bufferPosition] = colors[Int(state.colorPipe.ec)]
            }
            state.bufferPosition += 1
        }
        state.rasterX += 1
        if state.rasterX == configuration.xLimits.last {
            state.rasterX = 0
        }
    }
    
    @inline(__always) private func drawGraphicsPixel(_ i: Int) -> Int? {
        var graphicsPixel: Int? = nil
        // After 4 pixels, MCM changes start appearing, during pixel 5-7 it's a weird superposition where pixel data is interpreted in the next graphic mode,
        // but looks like the value is fetched as the old mode (eg. if MCM goes from 0 -> 1, pixel data is 1 bit as in non-MCM mode, but interpreted as a 2 bit MCM value)
        let mcm = i > 3 ? state.nextPipe.mcm : state.pipe.mcm
        if state.pipe.mcm && state.pipe.graphicsColorLine & 0x08 != 0 {
            if state.graphicsMulticolorFlipFlop {
                state.graphicsPixelData = state.graphicsShiftRegister >> 6
                if !mcm {
                    state.graphicsPixelData >>= 1
                }
            }
        } else {
            state.graphicsPixelData = state.graphicsShiftRegister >> 7
            if mcm {
                state.graphicsPixelData <<= 1
            }
        }
        // BMM/ECM changes start appearing after 4 pixels when rising, 6 when falling
        let bmm = !state.nextPipe.bmm && state.pipe.bmm ? i < 6 : (i > 3 ? state.nextPipe.bmm : state.pipe.bmm)
        let ecm = !state.nextPipe.ecm && state.pipe.ecm ? i < 6 : (i > 3 ? state.nextPipe.ecm : state.pipe.ecm)
        
        switch (ecm, bmm, mcm) {
        case (false, false, false): // Standard text mode (ECM/BMM/MCM=0/0/0)
            if state.graphicsPixelData != 0 {
                graphicsPixel = Int(state.pipe.graphicsColorLine)
            } else {
                state.screenBuffer[state.bufferPosition] = colors[Int(state.colorPipe.b0c)]
            }
        case (false, false, true): // Multicolor text mode (ECM/BMM/MCM=0/0/1)
            if state.pipe.graphicsColorLine & 0x08 == 0 {
                if state.graphicsPixelData != 0 {
                    graphicsPixel = Int(state.pipe.graphicsColorLine)
                } else {
                    state.screenBuffer[state.bufferPosition] = colors[Int(state.colorPipe.b0c)]
                }
            } else {
                switch state.graphicsPixelData {
                case 0:
                    state.screenBuffer[state.bufferPosition] = colors[Int(state.colorPipe.b0c)]
                case 1:
                    state.screenBuffer[state.bufferPosition] = colors[Int(state.colorPipe.b1c)]
                case 2:
                    graphicsPixel = Int(state.colorPipe.b2c)
                case 3:
                    graphicsPixel = Int(state.pipe.graphicsColorLine) & 0x07
                default:
                    break
                }
            }
        case (false, true, false): // Standard bitmap mode (ECM/BMM/MCM=0/1/0)
            if state.graphicsPixelData != 0 {
                graphicsPixel = Int((state.pipe.graphicsVideoMatrix & 0xF0) >> 4)
            } else {
                state.screenBuffer[state.bufferPosition] = colors[Int(state.pipe.graphicsVideoMatrix & 0x0F)]
            }
        case (false, true, true): // Multicolor bitmap mode (ECM/BMM/MCM=0/1/1)
            switch state.graphicsPixelData {
            case 0:
                state.screenBuffer[state.bufferPosition] = colors[Int(state.colorPipe.b0c)]
            case 1:
                state.screenBuffer[state.bufferPosition] = colors[Int((state.pipe.graphicsVideoMatrix & 0xF0) >> 4)]
            case 2:
                graphicsPixel = Int(state.pipe.graphicsVideoMatrix & 0x0F)
            case 3:
                graphicsPixel = Int(state.pipe.graphicsColorLine)
            default:
                break
            }
        case (true, false, false): // ECM text mode (ECM/BMM/MCM=1/0/0)
            if state.graphicsPixelData != 0 {
                graphicsPixel = Int(state.pipe.graphicsColorLine)
            } else {
                switch state.pipe.graphicsVideoMatrix >> 6 {
                case 0:
                    state.screenBuffer[state.bufferPosition] = colors[Int(state.colorPipe.b0c)]
                case 1:
                    state.screenBuffer[state.bufferPosition] = colors[Int(state.colorPipe.b1c)]
                case 2:
                    state.screenBuffer[state.bufferPosition] = colors[Int(state.colorPipe.b2c)]
                case 3:
                    state.screenBuffer[state.bufferPosition] = colors[Int(state.colorPipe.b3c)]
                default:
                    break
                }
            }
        case (true, false, true): // Invalid text mode (ECM/BMM/MCM=1/0/1)
            if state.pipe.graphicsColorLine & 0x08 == 0 {
                if state.graphicsPixelData != 0 {
                    graphicsPixel = 0
                } else {
                    state.screenBuffer[state.bufferPosition] = colors[0]
                }
            } else {
                if state.graphicsPixelData > 1 {
                    graphicsPixel = 0
                } else {
                    state.screenBuffer[state.bufferPosition] = colors[0]
                }
            }
        case (true, true, false): // Invalid bitmap mode 1 (ECM/BMM/MCM=1/1/0)
            if state.graphicsPixelData != 0 {
                graphicsPixel = 0
            } else {
                state.screenBuffer[state.bufferPosition] = colors[0]
            }
        case (true, true, true): // Invalid bitmap mode 2 (ECM/BMM/MCM=1/1/1)
            if state.graphicsPixelData > 1 {
                graphicsPixel = 0
            } else {
                state.screenBuffer[state.bufferPosition] = colors[0]
            }
        }
        
        state.graphicsShiftRegister <<= 1
        state.graphicsMulticolorFlipFlop = !state.graphicsMulticolorFlipFlop
        state.graphicsShiftRegisterRemainingBits = state.graphicsShiftRegisterRemainingBits &- 1
        
        return graphicsPixel
    }
    
    @inline(__always) private func drawSpritePixel(_ i: Int) -> (spritePixel: Int?, topSprite: Int?, spriteCollisions: UInt8) {
        var spritePixel: Int? = nil
        var topSprite: Int? = nil
        var spriteCollisions: UInt8 = 0
        if state.anySpriteDisplaying {
            for spriteIndex in (0...7).reversed() {
                if state.spriteDisplay[spriteIndex] {
                    let previousCycleRasterX = state.rasterX >= 8 ? state.rasterX - 8 : configuration.xLimits.last + state.rasterX - 8
                    if state.pipe.m_x[spriteIndex] == previousCycleRasterX {
                        state.spriteShiftRegisterCount[spriteIndex] = 24
                        state.spriteShiftRegisterPixelsPerShift[spriteIndex] = 0
                    }
                    if state.spriteShiftRegisterCount[spriteIndex] > 0 {
                        let multicolor = state.mmc & UInt8(1 << spriteIndex) != 0
                        let xExpansion = state.pipe.mxe & UInt8(1 << spriteIndex) != 0
                        var currentSpritePixel: Int? = nil
                        if multicolor {
                            switch (state.spriteSequencerData[spriteIndex] >> 22) & 0x03 {
                            case 1:
                                currentSpritePixel = Int(state.colorPipe.mm0)
                            case 2:
                                currentSpritePixel = Int(state.colorPipe.m_c[spriteIndex])
                            case 3:
                                currentSpritePixel = Int(state.colorPipe.mm1)
                            default:
                                break
                            }
                        } else {
                            if state.spriteSequencerData[spriteIndex] & 0x800000 != 0 {
                                currentSpritePixel = Int(state.colorPipe.m_c[spriteIndex])
                            }
                        }
                        state.spriteShiftRegisterPixelsPerShift[spriteIndex] += 1
                        let multicolorCount = multicolor ? 2 : 1
                        if state.spriteShiftRegisterPixelsPerShift[spriteIndex] >= (xExpansion ? multicolorCount << 1 : multicolorCount) {
                            if multicolor {
                                state.spriteSequencerData[spriteIndex] <<= 2
                                state.spriteShiftRegisterCount[spriteIndex] -= 2
                            } else {
                                state.spriteSequencerData[spriteIndex] <<= 1
                                state.spriteShiftRegisterCount[spriteIndex] -= 1
                            }
                            state.spriteShiftRegisterPixelsPerShift[spriteIndex] = 0
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
        }
        return (spritePixel, topSprite, spriteCollisions)
    }
    
}
