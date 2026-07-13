//
//  BikePlayApp.swift
//  BikePlay
//
//  Created by Göktuğ Toyguc on 12.07.2026.
//

import SwiftUI

@main
struct BikePlayApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(locationManager)
        }
        
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                break
            case .inactive:
                locationManager.endLiveActivity()
            case .active:
                break
            @unknown default:
                break
            }
        }
    }
}
