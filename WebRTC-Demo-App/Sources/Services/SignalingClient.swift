//
//  SignalClient.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import Foundation
import WebRTC
import SwiftPhoenixClient

protocol SignalClientDelegate: class {
    func signalClientDidConnect(_ signalClient: SignalingClient)
    func signalClientDidDisconnect(_ signalClient: SignalingClient)
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription)
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate)
}

final class SignalingClient {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let socket: Socket
    private let channel: Channel
    weak var delegate: SignalClientDelegate?
    
    init(socket: Socket) {
        self.socket = socket
        channel = socket.channel("match:00000177-6929-6fa5-b8e8-56408d820000")
    }
    
    func connect() {
        socket.onClose { [unowned self] in
            self.delegate?.signalClientDidDisconnect(self)
        }
        
        socket.onOpen { [unowned self] in
            self.delegate?.signalClientDidConnect(self)
        }
        
        socket.logger = { print($0) }

        socket.connect()
        
        channel.delegateOn("peer-message", to: self) { (self, message) in
            guard let body = message.payload["body"] as? String,
                  let data = body.data(using: .utf8) else { return }
            
            let message: Message
            
            do {
                message = try self.decoder.decode(Message.self, from: data)
            } catch {
                debugPrint("Warning: Could not decode incoming message: \(error)")
                return
            }
            
            switch message {
            case let .candidate(iceCandidate):
                self.delegate?.signalClient(self, didReceiveCandidate: iceCandidate.rtcIceCandidate)
            case let .sdp(sessionDescription):
                self.delegate?.signalClient(self, didReceiveRemoteSdp: sessionDescription.rtcSessionDescription)
            }
        }
        
        channel.join()
    }
    
    func send(sdp rtcSdp: RTCSessionDescription) {
        let message = Message.sdp(SessionDescription(from: rtcSdp))
        
        do {
            let dataMessage = try self.encoder.encode(message)
            channel.push("peer-message", payload: ["body": String(data: dataMessage, encoding: .utf8)!])
                .receive("ok") { _ in debugPrint("sent sdp")}
                .receive("error") { _ in debugPrint("error sending sdp")}
        } catch {
            debugPrint("Warning: Could not encode sdp: \(error)")
        }
    }
    
    func send(candidate rtcIceCandidate: RTCIceCandidate) {
        let message = Message.candidate(IceCandidate(from: rtcIceCandidate))
       
        do {
            let dataMessage = try self.encoder.encode(message)
            channel.push("peer-message", payload: ["body": String(data: dataMessage, encoding: .utf8)!])
                .receive("ok") { _ in debugPrint("sent ice candidate")}
                .receive("error") { _ in debugPrint("error sending ice candidate")}
        } catch {
            debugPrint("Warning: Could not encode candidate: \(error)")
        }
    }
}
