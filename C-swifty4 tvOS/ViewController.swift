//
//  ViewController.swift
//  C-swifty4 tvOS
//
//  Created by Fabio Ritrovato on 15/11/2015.
//  Copyright © 2015 orange in a day. All rights reserved.
//

import UIKit
import C64
import MultipeerConnectivity
import GameController

class ViewController: UIViewController {
    
    @IBOutlet fileprivate var graphicsView: GraphicsView!
    @IBOutlet fileprivate var fpsLabel: UILabel!
    
    fileprivate var startTime: CFTimeInterval = 0
    fileprivate var frames = 0
    
    fileprivate let c64: C64 = {
        let romConfig = C64ROMConfiguration(
            kernalData: try! Data(contentsOf: Bundle.main.url(forResource: "kernal", withExtension: nil, subdirectory:"ROM")!),
            basicData: try! Data(contentsOf: Bundle.main.url(forResource: "basic", withExtension: nil, subdirectory:"ROM")!),
            characterData: try! Data(contentsOf: Bundle.main.url(forResource: "chargen", withExtension: nil, subdirectory:"ROM")!))
        let config = C64Configuration(rom: romConfig,
                                      vic: .pal,
                                      c1541: C1541Configuration(rom: C1541ROMConfiguration(c1541Data: try! Data(contentsOf: Bundle.main.url(forResource: "1541", withExtension: nil, subdirectory:"ROM")!))))
        return C64(configuration: config)
    }()
    
    let peerId = MCPeerID(displayName: UIDevice.current.name)
    lazy var session: MCSession = {
        return MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .none)
    }()
    lazy var advertiser: MCNearbyServiceAdvertiser = {
        return MCNearbyServiceAdvertiser(peer: peerId, discoveryInfo: nil, serviceType: "c-swifty4")
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let resolution = c64.configuration.vic.resolution
        graphicsView.setTextureSize(CGSize(width: resolution.width, height: resolution.height),
                                    safeArea: c64.configuration.vic.safeArea)

        c64.delegate = self
        c64.run()
    
        session.delegate = self
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidConnect, object: nil, queue: nil) { _ in
            GCController.controllers().first?.microGamepad?.dpad.valueChangedHandler = { _, x, y in
                switch x {
                case _ where x > 0.5:
                    self.c64.setJoystick2XAxis(.right)
                case _ where x < 0.5:
                    self.c64.setJoystick2XAxis(.left)
                default:
                    self.c64.setJoystick2XAxis(.none)
                }
                switch y {
                case _ where y > 0.5:
                    self.c64.setJoystick2YAxis(.up)
                case _ where y < 0.5:
                    self.c64.setJoystick2YAxis(.down)
                default:
                    self.c64.setJoystick2YAxis(.none)
                }
            }
        }
    }
    
    @discardableResult
    func handleFile(url: URL) -> Bool {
        var result = true
        switch String(url.pathExtension).lowercased() {
        case "txt":
            if let string = try? String(contentsOf: url, encoding: String.Encoding.utf8) {
                c64.loadString(string)
            } else {
                result = false
            }
        case "prg", "rw":
            c64.loadPRGFile(try! Data(contentsOf: url))
            c64.loadString("RUN\n")
        case "d64":
            c64.loadD64File(try! Data(contentsOf: url))
        case "p00":
            c64.loadP00File(try! Data(contentsOf: url))
        default:
            result = false
        }
        c64.run()
        return result
    }

}

extension ViewController: C64Delegate {
    
    func C64VideoFrameReady(_ c64: C64) {
        graphicsView.setData(c64.screenBuffer())
        frames += 1
        if frames == 60 {
            let newTime = CACurrentMediaTime()
            let time = newTime - startTime
            fpsLabel.text = "\(Int(60 / time))"
            startTime = newTime
            frames = 0
        }
    }
    
    func C64DidBreak(_ c64: C64) {}
    
    func C64DidCrash(_ c64: C64) {}
    
}

extension ViewController: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
    
}

extension ViewController: MCSessionDelegate {
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if data.count == 2 {
            let key = UInt16(data[0]) << 8 | UInt16(data[1])
            c64.pressSpecialKey(SpecialKey(rawValue: key)!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
                self.c64.releaseSpecialKey(SpecialKey(rawValue: key)!)
            }
        } else if let key = data.first {
            c64.pressKey(key)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                self.c64.releaseKey(key)
            }
        }
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {}
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        handleFile(url: localURL!)
    }
    
}
