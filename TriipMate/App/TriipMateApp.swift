//
//  TriipMateApp.swift
//  TriipMate
//
//  Phase 1 — Auth & Profiles entry point.
//

import SwiftUI
import FirebaseCore

@main
struct TriipMateApp: App {
    @StateObject private var auth = AuthViewModel()

    init() {
        FirebaseApp.configure()
        FirebaseConfig.useEmulatorsIfDebug()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
        }
    }
}

/// Routes to the correct top-level screen based on auth state.
struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        switch auth.state {
        case .loading:
            ProgressView()
        case .signedOut:
            WelcomeView()
        case .signedIn(let user) where user.role == nil:
            RoleSelectionView()
        case .signedIn:
            ProfileView()
        }
    }
}
