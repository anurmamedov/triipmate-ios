//
//  LoginView.swift
//  TriipMate
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        Form {
            Section("Sign In") {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Password", text: $password)
            }

            if let error = auth.errorMessage {
                Section { Text(error).foregroundStyle(.red) }
            }

            Section {
                Button {
                    Task { await auth.signIn(email: email, password: password) }
                } label: {
                    HStack {
                        if auth.isWorking { ProgressView() }
                        Text("Sign In")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(email.isEmpty || password.isEmpty || auth.isWorking)
            }
        }
        .navigationTitle("Log In")
    }
}

#Preview {
    NavigationStack { LoginView().environmentObject(AuthViewModel()) }
}
