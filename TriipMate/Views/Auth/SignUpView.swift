//
//  SignUpView.swift
//  TriipMate
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        Form {
            Section("Account") {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Password (min 8 chars)", text: $password)
            }

            if let error = auth.errorMessage {
                Section { Text(error).foregroundStyle(.red) }
            }

            Section {
                Button {
                    Task { await auth.signUp(email: email, password: password) }
                } label: {
                    HStack {
                        if auth.isWorking { ProgressView() }
                        Text("Create Account")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!isValid || auth.isWorking)
            }
        }
        .navigationTitle("Sign Up")
    }

    private var isValid: Bool {
        email.contains("@") && password.count >= 8
    }
}

#Preview {
    NavigationStack { SignUpView().environmentObject(AuthViewModel()) }
}
