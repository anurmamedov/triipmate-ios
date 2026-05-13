//
//  ProfileView.swift
//  TriipMate
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            Group {
                if case .signedIn(let user) = auth.state {
                    profileContent(user: user)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { isEditing = true }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign Out", role: .destructive) { auth.signOut() }
                }
            }
            .sheet(isPresented: $isEditing) {
                if case .signedIn(let user) = auth.state {
                    EditProfileView(user: user)
                }
            }
        }
    }

    @ViewBuilder
    private func profileContent(user: TMUser) -> some View {
        List {
            Section {
                HStack(spacing: 16) {
                    AsyncImage(url: user.avatarURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())

                    VStack(alignment: .leading) {
                        Text(user.name.isEmpty ? "Set your name" : user.name)
                            .font(.headline)
                        Text(user.email).foregroundStyle(.secondary)
                        if let role = user.role {
                            Text(role.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(TMTheme.surface)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Section("Bio") {
                Text(user.bio.isEmpty ? "—" : user.bio)
            }
        }
    }
}

#Preview {
    ProfileView().environmentObject(AuthViewModel())
}
