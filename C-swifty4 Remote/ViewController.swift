//
//  ViewController.swift
//  C-swifty4 Remote
//
//  Created by Fabio on 22/11/2017.
//  Copyright © 2017 orange in a day. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController {
    
    let peerId = MCPeerID(displayName: UIDevice.current.name)
    lazy var session: MCSession = {
        return MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .none)
    }()
    lazy var browser: MCNearbyServiceBrowser = {
        MCNearbyServiceBrowser(peer: peerId, serviceType: "c-swifty4")
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        browser.delegate = self
        browser.startBrowsingForPeers()

        becomeFirstResponder()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

}

extension ViewController: UIKeyInput {
    
    var autocorrectionType: UITextAutocorrectionType {
        get { return .no }
        set {}
    }
    
    var keyboardAppearance: UIKeyboardAppearance {
        get { return .dark }
        set {}
    }
    
    var hasText: Bool {
        return true
    }
    
    func insertText(_ text: String) {
        if text == "\n" {
            try? session.send(Data([0x00, 0x01]), toPeers: session.connectedPeers, with: .reliable)
        } else {
            let char = text.utf8[text.utf8.startIndex]
            try? session.send(Data([char]), toPeers: session.connectedPeers, with: .reliable)
        }
    }
    
    func deleteBackward() {
        try? session.send(Data([0x00, 0x00]), toPeers: session.connectedPeers, with: .reliable)
    }
    
}

extension ViewController: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {

    }

}
