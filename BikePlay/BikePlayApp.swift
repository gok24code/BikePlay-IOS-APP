//
//  BikePlayApp.swift (PRODUCTION)
//  BikePlay
//
//  Swift 6 Compliance:
//  ✅ onChange with new signature (iOS 17+)
//  ✅ Proper @MainActor lifecycle
//  ✅ Proper async handling
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
        
        // ✅ FIX: Deprecated onChange(of:perform:) → onChange(of:perform:) with new signature
        // iOS 17+ requires: onChange(of:initial:_:)
        .onChange(of: scenePhase, initial: false) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Scene Phase Handler
    @MainActor
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // Arka planda: konum tracking açık kalsın
            break
        case .inactive:
            // Uygulama ön plandan çıkıyor: Activity'i pürüzsüzce kapat
            locationManager.endLiveActivity()
        case .active:
            // Uygulama öne geldi
            break
        @unknown default:
            break
        }
    }
}
