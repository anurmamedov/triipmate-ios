//
//  EditProfileView.swift
//  TriipMate
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: ProfileViewModel

    init(user: TMUser) {
        _vm = StateObject(wrappedValue: ProfileViewModel(user: user))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Your name", text: $vm.user.name)
                }
                Section("Bio") {
                    TextField("A short bio", text: $vm.user.bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                if let error = vm.errorMessage {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await vm.save()
                            if vm.errorMessage == nil { dismiss() }
                        }
                    } label: {
                        if vm.isSaving { ProgressView() } else { Text("Save") }
                    }
                    .disabled(vm.isSaving)
                }
            }
        }
    }
}

#Preview {
    EditProfileView(user: TMUser.newProfile(uid: "abc", email: "a@b.com"))
}
