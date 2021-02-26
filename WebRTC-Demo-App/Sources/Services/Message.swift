//
//  Message.swift
//  WebRTC-Demo
//
//  Created by Stasel on 20/02/2019.
//  Copyright © 2019 Stasel. All rights reserved.
//

import Foundation

enum Message {
    case sdp(SessionDescription)
    case candidate(IceCandidate)
}

extension Message: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case String(describing: SessionDescription.self):
            self = .sdp(try container.decode(SessionDescription.self, forKey: .content))
        case "video-answer":
            self = .sdp(try container.decode(SessionDescription.self, forKey: .content))
        case "ice-candidate":
            self = .candidate(try container.decode(IceCandidate.self, forKey: .content))
        default:
            throw DecodeError.unknownType
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .sdp(sessionDescription):
            try container.encode(sessionDescription, forKey: .content)
            try container.encode(String(describing: SessionDescription.self), forKey: .type)
        case let .candidate(iceCandidate):
            try container.encode(iceCandidate, forKey: .content)
            try container.encode("ice-candidate", forKey: .type)
        }
    }
    
    enum DecodeError: Error {
        case unknownType
    }
    
    enum CodingKeys: String, CodingKey {
        case type, content
    }
}
