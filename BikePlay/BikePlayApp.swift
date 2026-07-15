//
//  BikePlayApp.swift
//  BikePlay
//
//  Created by Göktuğ Toyguc on 12.07.2026.
//

import SwiftUI
import SwiftData

@main
struct BikePlayApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(locationManager)
        }
        .modelContainer(.shared)
        .onChange(of: scenePhase, initial: false) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    @MainActor
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .inactive:
            // Uygulama ön plandan çıkarken canlı etkinliği kapat
            locationManager.endLiveActivity()
        case .active, .background:
            break
        @unknown default:
            break
        }
    }
}
