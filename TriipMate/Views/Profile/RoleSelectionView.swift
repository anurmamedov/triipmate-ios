//
//  RoleSelectionView.swift
//  TriipMate
//

import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm: ProfileViewModel

    init() {
        _vm = StateObject(wrappedValue: ProfileViewModel(user: TMUser.newProfile(uid: "", email: "")))
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("How will you use TriipMate?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("You can change this later in Settings.")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 48)

            Spacer()

            ForEach(UserRole.allCases) { role in
                Button {
                    Task { await vm.setRole(role) }
                } label: {
                    HStack {
                        Image(systemName: role == .driver ? "car.fill" : "figure.wave")
                        Text(role.displayName)
                            .font(.headline)
                        Spacer()
                    }
                    .padding()
                    .background(TMTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }

            Spacer()
        }
    }
}

#Preview {
    RoleSelectionView().environmentObject(AuthViewModel())
}
