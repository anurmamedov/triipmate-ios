//
//  FirebaseConfig.swift
//  TriipMate
//
//  Routes the Firebase SDK at the local emulator suite in DEBUG builds.
//  Release builds (TestFlight, App Store) hit the real Firebase project.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

enum FirebaseConfig {
    /// Call once at app launch, immediately after `FirebaseApp.configure()`.
    static func useEmulatorsIfDebug() {
        #if DEBUG
        let host = "localhost"
        Auth.auth().useEmulator(withHost: host, port: 9099)

        let settings = Firestore.firestore().settings
        settings.host = "\(host):8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings

        Storage.storage().useEmulator(withHost: host, port: 9199)

        print("Firebase emulators wired: Auth :9099  Firestore :8080  Storage :9199")
        #endif
    }
}
