//
//  VIC.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 10/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

import Foundation

private struct VICState: ComponentState {
    
    //MARK: Memory
    private var ioMemory: [UInt8] = [UInt8](count: 64, repeatedValue: 0)
    private var videoMatrix: [UInt8] = [UInt8](count: 40, repeatedValue: 0)
    private var colorLine: [UInt8] = [UInt8](count: 40, repeatedValue: 0)
    private var mp: UInt8 = 0 // Sprite Pointer
    private let screenBuffer1 = UnsafeMutablePointer<UInt32>(calloc(512 * 512, sizeof(UInt32)))
    private let screenBuffer2 = UnsafeMutablePointer<UInt32>(calloc(512 * 512, sizeof(UInt32)))
    //MARK: -
    
    private var currentCycle = 1
    private var currentLine: UInt16 = 0
    
    //MARK: Internal Registers
    private var vc: UInt16 = 0
    private var vcbase: UInt16 = 0
    private var rc: UInt8 = 0
    private var vmli: UInt16 = 0
    private var displayState = false
    private var rasterX: UInt16 = 0x19C // NTSC
    private var mainBorder = false
    private var verticalBorder = false
    private var ref: UInt8 = 0
    private var mc: [UInt8] = [UInt8](count: 8, repeatedValue: 0)
    private var mcbase: [UInt8] = [UInt8](count: 8, repeatedValue: 0)
    private var yExpansion: [Bool] = [Bool](count: 8, repeatedValue: true)
    //MARK: -
    
    //MARK: Registers
    private var m_x: [UInt16] = [UInt16](count: 8, repeatedValue: 0) // X Coordinate Sprite
    private var m_y: [UInt8] = [UInt8](count: 8, repeatedValue: 0) // Y Coordinate Sprite
    private var yScroll: UInt8 = 0 // Y Scroll
    private var den = false // Display Enable
    private var bmm = false // Bit Map Mode
    private var ecm = false // Extended Color Mode
    private var mcm = false // Multi Color Mode
    private var raster: UInt16 = 0 // Raster Counter
    private var me: UInt8 = 0 // Sprite Enabled
    private var mye: UInt8 = 0 // Sprite Y Expansion
    private var vm: UInt8 = 0 // Video matrix base address
    private var cb: UInt8 = 0 // Character base address
    private var ec: UInt8 = 0 // Border Color
    private var mmc: UInt8 = 0 // Sprite Multicolor
    private var b0c: UInt8 = 0 // Background Color 0
    private var b1c: UInt8 = 0 // Background Color 1
    private var b2c: UInt8 = 0 // Background Color 2
    private var b3c: UInt8 = 0 // Background Color 3
    private var mm0: UInt8 = 0 // Sprite Multicolor 0
    private var mm1: UInt8 = 0 // Sprite Multicolor 1
    private var m_c: [UInt8] = [UInt8](count: 8, repeatedValue: 0) // Color Sprite
    //MARK: -
    
    //MARK: Graphic Sequencer
    private var graphicsSequencerData: UInt8 = 0
    private var graphicsSequencerShiftRegister: UInt8 = 0
    private var graphicsSequencerVideoMatrix: UInt8 = 0
    private var graphicsSequencerColorLine: UInt8 = 0
    //MARK: -
    
    //MARK: Sprite Sequencers
    private var spriteSequencerData: [UInt32] = [UInt32](count: 8, repeatedValue: 0)
    //MARK: -
    
    //MARK: Bus
    private var addressBus: UInt16 = 0
    private var dataBus: UInt8 = 0
    //MARK: -
    
    //MARK: Helpers
    private var memoryBankAddress: UInt16 = 0
    private var bufferPosition: Int = 0
    private var badLinesEnabled = false
    private var isBadLine = false
    private var currentSprite: UInt8 = 2
    private var spriteDma: [Bool] = [Bool](count: 8, repeatedValue: false)
    private var spriteDisplay: [Bool] = [Bool](count: 8, repeatedValue: false)
    private var anySpriteDisplaying = false
    private var spriteShiftRegisterCount: [Int] = [Int](count: 8, repeatedValue: 0)
    //MARK: -
    
}

final internal class VIC: Component {
    
    private var state = VICState()
    func componentState() -> ComponentState {
        return state
    }
    
    internal weak var memory: C64Memory!
    
    private var currentScreenBuffer: UnsafeMutablePointer<UInt32>
    internal var screenBuffer: UnsafeMutablePointer<UInt32> {
        get {
            return currentScreenBuffer == state.screenBuffer1 ? state.screenBuffer2 : state.screenBuffer1
        }
    }
    
    private let borderLeftComparisonValue: UInt16 = 24
    private let borderRightComparisonValue: UInt16 = 344
    private let borderTopComparisonValue: UInt16 = 51
    private let borderBottomComparisonValue: UInt16 = 251
    
    private let colors: [UInt32] = [
        UInt32(truncatingBitPattern: (0xFF101010 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFFFFFFF as UInt64)),
        UInt32(truncatingBitPattern: (0xFF4040E0 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFFFFF60 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFE060E0 as UInt64)),
        UInt32(truncatingBitPattern: (0xFF40E040 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFE04040 as UInt64)),
        UInt32(truncatingBitPattern: (0xFF40FFFF as UInt64)),
        UInt32(truncatingBitPattern: (0xFF40A0E0 as UInt64)),
        UInt32(truncatingBitPattern: (0xFF48749C as UInt64)),
        UInt32(truncatingBitPattern: (0xFFA0A0FF as UInt64)),
        UInt32(truncatingBitPattern: (0xFF545454 as UInt64)),
        UInt32(truncatingBitPattern: (0xFF888888 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFA0FFA0 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFFFA0A0 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFC0C0C0 as UInt64)),
    ]
    
    init() {
        self.currentScreenBuffer = state.screenBuffer1
    }
    
    internal func readByte(position: UInt8) -> UInt8 {
        switch position {
        case 0x00, 0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E:
            return UInt8(truncatingBitPattern: state.m_x[Int(position >> 1)])
        case 0x01, 0x03, 0x05, 0x07, 0x09, 0x0B, 0x0D, 0x0F:
            return state.m_y[Int((position - 1) >> 1)]
        case 0x10:
            let value = (state.m_x[0] & 0xFF00) >> 8 |
                (state.m_x[1] & 0xFF00) >> 7 |
                (state.m_x[2] & 0xFF00) >> 6 |
                (state.m_x[3] & 0xFF00) >> 5 |
                (state.m_x[4] & 0xFF00) >> 4 |
                (state.m_x[5] & 0xFF00) >> 3 |
                (state.m_x[6] & 0xFF00) >> 2 |
                (state.m_x[7] & 0xFF00) >> 1
            return UInt8(truncatingBitPattern: value)
        case 0x11:
            return state.yScroll | (state.den ? 0x10 : 0) | (state.bmm ? 0x20 : 0) | (state.ecm ? 0x40 : 0) | UInt8((state.raster & 0x100) >> 1)
        case 0x12:
            return UInt8(truncatingBitPattern: state.raster)
        case 0x15:
            return state.me
        case 0x16:
            return (state.mcm ? 0x10 : 0) //TODO: missing bit registers
        case 0x17:
            return state.mye
        case 0x18:
            return state.vm << 4 | state.cb << 1 | 0x01
        case 0x19:
            //TEMP: force NTSC timing
            return 0x70
        case 0x1C:
            return state.mmc
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
    
    internal func writeByte(position:UInt8, byte: UInt8) {
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
            state.den = byte & 0x10 != 0
            state.bmm = byte & 0x20 != 0
            state.ecm = byte & 0x40 != 0
        case 0x15:
            state.me = byte
        case 0x16:
            state.mcm = byte & 0x10 != 0
        case 0x17:
            state.mye = byte
        case 0x18:
            state.cb = (byte & 0x0E) >> 1
            state.vm = (byte & 0xF0) >> 4
        case 0x1C:
            state.mmc = byte
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
    
    internal func setMemoryBank(bankNumber: UInt8) {
        state.memoryBankAddress = UInt16(~bankNumber & 0x3) << 14
    }

    private func memoryAccess(position: UInt16) -> UInt8 {
        state.addressBus = state.memoryBankAddress &+ position
        if state.addressBus & 0x7000 == 0x1000 { // address in 0x1000...0x1FFF or 0x9000...0x9FFF
            // Read from character ROM
            state.dataBus = memory.readROMByte(0xC000 &+ position)
        } else {
            state.dataBus = memory.readRAMByte(state.addressBus)
        }
        return state.dataBus
    }
    
    internal func cycle() {
        
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
        case 11...15:
            rAccess()
        case 58:
            if state.rc == 7 {
                state.displayState = false
                state.vcbase = state.vc
            }
            if state.displayState {
                state.rc = (state.rc + 1) & 7
            }
        case 63:
            if state.raster == borderBottomComparisonValue {
                state.verticalBorder = true
            } else if state.raster == borderTopComparisonValue && state.den {
                state.verticalBorder = false
            }
        case 65:
            if ++state.raster == 263 {
                state.raster = 0
                state.bufferPosition = 0
                currentScreenBuffer = currentScreenBuffer == state.screenBuffer1 ? state.screenBuffer2 : state.screenBuffer1
            }
        default:
            break
        }
        
        // First half-cycle
        let cyclesPerRaster = 65 // NTSC
        if state.currentCycle != cyclesPerRaster {
            draw()
        }
        switch state.currentCycle {
        case 1, 3, 5, 7, 9:
            pAccess()
        case 2, 4, 6, 8, 10:
            if state.spriteDma[Int(state.currentSprite)] {
                sAccess(1)
            }
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
        case 17...54:
            gAccess()
        case 55:
            gAccess()
            for i in 0...7 {
                if state.mye & UInt8(1 << i) != 0 {
                    state.yExpansion[i] = !state.yExpansion[i]
                }
            }
            fallthrough
        case 56:
            for i in 0...7 {
                if state.me & UInt8(1 << i) != 0 && state.m_y[i] == UInt8(truncatingBitPattern: state.raster) {
                    state.spriteDma[i] = true
                    state.mcbase[i] = 0
                    if state.mye & UInt8(1 << i) != 0 {
                        state.yExpansion[i] = false
                    }
                }
            }
        case cyclesPerRaster - 5:
            pAccess()
            for i in 0...7 {
                state.mc[i] = state.mcbase[i]
                if state.spriteDma[i] {
                    if state.m_y[i] == UInt8(truncatingBitPattern: state.raster) {
                        state.spriteDisplay[i] = true
                        state.anySpriteDisplaying = true
                    }
                } else {
                    state.spriteDisplay[i] = false
                }
            }
            if state.anySpriteDisplaying && state.spriteDisplay.indexOf(true) == nil {
                state.anySpriteDisplaying = false
            }
        case cyclesPerRaster - 3, cyclesPerRaster - 1:
            pAccess()
        case cyclesPerRaster - 4, cyclesPerRaster - 2, cyclesPerRaster:
            if state.spriteDma[Int(state.currentSprite)] {
                sAccess(1)
            }
        default:
            break
        }
        
        // Second half-cycle
        if state.currentCycle != cyclesPerRaster {
            draw()
        }
        switch state.currentCycle {
        case 1, 3, 5, 7, 9:
            if state.spriteDma[Int(state.currentSprite)] {
                sAccess(0)
            }
        case 2, 4, 6, 8, 10:
            if state.spriteDma[Int(state.currentSprite)] {
                sAccess(2)
            }
        case 15...54:
            cAccess()
        case cyclesPerRaster - 5, cyclesPerRaster - 3, cyclesPerRaster - 1:
            if state.spriteDma[Int(state.currentSprite)] {
                sAccess(0)
            }
        case cyclesPerRaster - 4, cyclesPerRaster - 2, cyclesPerRaster:
            if state.spriteDma[Int(state.currentSprite)] {
                sAccess(2)
            }
        default:
            break
        }

        if state.currentCycle++ == cyclesPerRaster {
            state.currentCycle = 1
        }
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
                state.graphicsSequencerData = memoryAccess(UInt16(state.cb & 0x04) << 11 | state.vc << 3 | UInt16(state.rc))
            } else {
                state.graphicsSequencerData = memoryAccess(UInt16(state.cb) << 11 | (UInt16(state.videoMatrix[Int(state.vmli)]) & (state.ecm ? 0x3F : 0xFF)) << 3 | UInt16(state.rc))
            }
            state.graphicsSequencerShiftRegister = state.graphicsSequencerData
            state.graphicsSequencerVideoMatrix = state.videoMatrix[Int(state.vmli)]
            state.graphicsSequencerColorLine = state.colorLine[Int(state.vmli)]
            state.vc = (state.vc + 1) & 0x3FF
            state.vmli = (state.vmli + 1) & 0x3F
        } else {
            //TODO: something here
        }
    }
    
    // Sprite data pointers access
    private func pAccess() {
        state.currentSprite = (state.currentSprite + 1) & 7
        state.mp = memoryAccess(UInt16(state.vm) << 10 | 0x03F8 | UInt16(state.currentSprite))
    }
    
    // Sprite data access
    private func sAccess(accessNumber: Int) {
        let data = memoryAccess(UInt16(state.mp) << 6 | UInt16(state.mc[Int(state.currentSprite)]))
        state.spriteSequencerData[Int(state.currentSprite)] |= UInt32(data) << UInt32(8 * (2 - accessNumber))
        state.mc[Int(state.currentSprite)]++
    }
    
    // DRAM refresh
    private func rAccess() {
        memoryAccess(0x3F00 | UInt16(state.ref))
        state.ref = state.ref &- 1
    }
    
    // Draw 4 pixels (half cycle)
    private func draw() {
        for i in 0...3 {
            if (state.rasterX >= 0x1E8 || state.rasterX < 0x18C) && state.raster >= 28 { // 0x1E8 first visible X coord. 0x18C last visible NTSC
                if !state.mainBorder && !state.verticalBorder {
                    if (!state.mcm && !state.bmm) || (state.mcm && state.graphicsSequencerColorLine & 0x08 == 0) {
                        if state.graphicsSequencerShiftRegister >> 7 != 0 {
                            currentScreenBuffer[state.bufferPosition] = colors[Int(state.graphicsSequencerColorLine)]
                        } else {
                            if state.ecm {
                                switch (state.graphicsSequencerVideoMatrix & 0xC0) >> 6 {
                                case 0:
                                    currentScreenBuffer[state.bufferPosition] = colors[Int(state.b0c)]
                                case 1:
                                    currentScreenBuffer[state.bufferPosition] = colors[Int(state.b1c)]
                                case 2:
                                    currentScreenBuffer[state.bufferPosition] = colors[Int(state.b2c)]
                                case 3:
                                    currentScreenBuffer[state.bufferPosition] = colors[Int(state.b3c)]
                                default:
                                    break
                                }
                            } else {
                                currentScreenBuffer[state.bufferPosition] = colors[Int(state.b0c)]
                            }
                        }
                        state.graphicsSequencerShiftRegister <<= 1
                    } else if state.bmm {
                        if state.mcm {
                            switch (state.graphicsSequencerShiftRegister & 0xC0) >> 6 {
                            case 0:
                                currentScreenBuffer[state.bufferPosition] = colors[Int(state.b0c)]
                            case 1:
                                currentScreenBuffer[state.bufferPosition] = colors[Int((state.graphicsSequencerVideoMatrix & 0xF0) >> 4)]
                            case 2:
                                currentScreenBuffer[state.bufferPosition] = colors[Int(state.graphicsSequencerVideoMatrix & 0x0F)]
                            case 3:
                                currentScreenBuffer[state.bufferPosition] = colors[Int(state.graphicsSequencerColorLine)]
                            default:
                                break
                            }
                            if i % 2 == 1 {
                                state.graphicsSequencerShiftRegister <<= 2
                            }
                        } else {
                            if state.graphicsSequencerShiftRegister >> 7 != 0 {
                                currentScreenBuffer[state.bufferPosition] = colors[Int((state.graphicsSequencerVideoMatrix & 0xF0) >> 4)]
                            } else {
                                currentScreenBuffer[state.bufferPosition] = colors[Int(state.graphicsSequencerVideoMatrix & 0x0F)]
                            }
                            state.graphicsSequencerShiftRegister <<= 1
                        }
                    } else {
                        switch (state.graphicsSequencerShiftRegister & 0xC0) >> 6 {
                        case 0:
                            currentScreenBuffer[state.bufferPosition] = colors[Int(state.b0c)]
                        case 1:
                            currentScreenBuffer[state.bufferPosition] = colors[Int(state.b1c)]
                        case 2:
                            currentScreenBuffer[state.bufferPosition] = colors[Int(state.b2c)]
                        case 3:
                            currentScreenBuffer[state.bufferPosition] = colors[Int(state.graphicsSequencerColorLine) & 0x07]
                        default:
                            break
                        }
                        if i % 2 == 1 {
                            state.graphicsSequencerShiftRegister <<= 2
                        }
                    }
                }
                if state.anySpriteDisplaying {
                    //TODO: z priority, expansion, collisions
                    for spriteIndex in 0...7 {
                        if state.spriteDisplay[spriteIndex] {
                            if state.m_x[spriteIndex] == state.rasterX {
                                state.spriteShiftRegisterCount[spriteIndex] = 24
                            }
                            if state.spriteShiftRegisterCount[spriteIndex] > 0 {
                                if state.mmc & UInt8(1 << spriteIndex) != 0 {
                                    switch (state.spriteSequencerData[spriteIndex] >> 22) & 0x03 {
                                    case 1:
                                        currentScreenBuffer[state.bufferPosition] = colors[Int(state.mm0)]
                                    case 2:
                                        currentScreenBuffer[state.bufferPosition] = colors[Int(state.m_c[spriteIndex])]
                                    case 3:
                                        currentScreenBuffer[state.bufferPosition] = colors[Int(state.mm1)]
                                    default:
                                        break
                                    }
                                    if i % 2 == 1 {
                                        state.spriteSequencerData[spriteIndex] <<= 2
                                        state.spriteShiftRegisterCount[spriteIndex] -= 2
                                    }
                                } else {
                                    if state.spriteSequencerData[spriteIndex] & 0x800000 != 0 {
                                        currentScreenBuffer[state.bufferPosition] = colors[Int(state.m_c[spriteIndex])]
                                    }
                                    state.spriteSequencerData[spriteIndex] <<= 1
                                    state.spriteShiftRegisterCount[spriteIndex]--
                                }
                            }
                        }
                    }
                }
                if state.mainBorder || state.verticalBorder {
                    currentScreenBuffer[state.bufferPosition] = colors[Int(state.ec)]
                }
                ++state.bufferPosition
            }
        
            if ++state.rasterX == 0x200 {
                state.rasterX = 0
            }
            
            if state.rasterX == borderRightComparisonValue {
                state.mainBorder = true
            } else if state.rasterX == borderLeftComparisonValue {
                if state.raster == borderBottomComparisonValue {
                    state.verticalBorder = true
                } else if state.raster == borderTopComparisonValue && state.den {
                    state.verticalBorder = false
                }
                if !state.verticalBorder {
                    state.mainBorder = false
                }
            }
        }
    }
    
}
