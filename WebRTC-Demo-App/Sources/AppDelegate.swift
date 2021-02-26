//
//  AppDelegate.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import UIKit
import SwiftPhoenixClient

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    internal var window: UIWindow?
    private let config = Config.default
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = self.buildMainViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
    
    private func buildMainViewController() -> UIViewController {
        let webRTCClient = WebRTCClient(iceServers: ["stun:global.stun.twilio.com:3478?transport=udp"])
        let signalClient = self.buildSignalingClient()
        let mainViewController = MainViewController(signalClient: signalClient, webRTCClient: webRTCClient)
        let navViewController = UINavigationController(rootViewController: mainViewController)
        
        if #available(iOS 11.0, *) {
            navViewController.navigationBar.prefersLargeTitles = true
        } else {
            navViewController.navigationBar.isTranslucent = false
        }
        
        return navViewController
    }
    
    private func buildSignalingClient() -> SignalingClient {
        let socket = Socket("http://192.168.1.51:4000/api/socket", params: ["token": "q--FExlXrZZTOcQtqQEHlcZv23myD0YnPSXxH0vcduw"])
        return SignalingClient(socket: socket)
    }
}

