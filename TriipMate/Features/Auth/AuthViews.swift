import SwiftUI

struct AuthRootView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        NavigationStack {
            WelcomeView()
        }
        .tint(Color.tmGreen)
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "car.2.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(Color.tmGreen)
                    .frame(width: 104, height: 104)
                    .background(Color.tmCloud)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(spacing: 10) {
                    Text("TriipMate")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(Color.tmInk)
                    Text("Travel together. Split gas, tolls, and rental costs with trusted people going your way.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.tmSlate)
                        .padding(.horizontal)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                NavigationLink {
                    RegisterView()
                } label: {
                    Label("Create Account", systemImage: "person.badge.plus.fill")
                        .authPrimaryButton()
                }

                NavigationLink {
                    LoginView()
                } label: {
                    Label("Log In", systemImage: "arrow.right.circle.fill")
                        .authSecondaryButton()
                }
            }
        }
        .padding(24)
        .background(Color.tmMist.ignoresSafeArea())
    }
}

struct LoginView: View {
    @EnvironmentObject private var session: AppSession
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        AuthFormLayout(title: "Welcome back", subtitle: "Log in to continue planning shared trips.") {
            AuthTextField(title: "Email", text: $email, icon: "at")
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
            AuthSecureField(title: "Password", text: $password, icon: "lock.fill")
                .textContentType(.password)

            NavigationLink("Forgot password?") {
                ForgotPasswordView()
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .trailing)

            Button {
                Task {
                    await session.login(email: email, password: password)
                }
            } label: {
                HStack {
                    if session.isAuthWorking {
                        ProgressView()
                    }
                    Label("Log In", systemImage: "arrow.right.circle.fill")
                }
                .authPrimaryButton()
            }
            .disabled(email.isEmpty || password.isEmpty || session.isAuthWorking)

            AuthErrorMessage(message: session.authError)
        }
        .navigationTitle("Log In")
        .onAppear { session.clearAuthFeedback() }
    }
}

struct RegisterView: View {
    @EnvironmentObject private var session: AppSession
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        AuthFormLayout(title: "Create your account", subtitle: "Start with the basics so other travelers know who they are meeting.") {
            AuthTextField(title: "First name", text: $firstName, icon: "person.fill")
            AuthTextField(title: "Last name", text: $lastName, icon: "person.fill")
            AuthTextField(title: "Email", text: $email, icon: "envelope.fill")
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
            AuthTextField(title: "Phone number", text: $phone, icon: "phone.fill")
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
            AuthSecureField(title: "Password", text: $password, icon: "lock.fill")
                .textContentType(.newPassword)
            AuthSecureField(title: "Confirm password", text: $confirmPassword, icon: "lock.shield.fill")
                .textContentType(.newPassword)

            Button {
                Task {
                    await session.register(
                        firstName: firstName,
                        lastName: lastName,
                        email: email,
                        phone: phone,
                        password: password,
                        confirmPassword: confirmPassword
                    )
                }
            } label: {
                HStack {
                    if session.isAuthWorking {
                        ProgressView()
                    }
                    Label("Create Account", systemImage: "checkmark.circle.fill")
                }
                .authPrimaryButton()
            }
            .disabled(
                firstName.isEmpty || lastName.isEmpty || email.isEmpty || phone.isEmpty ||
                password.isEmpty || confirmPassword.isEmpty || session.isAuthWorking
            )

            AuthErrorMessage(message: session.authError)
        }
        .navigationTitle("Register")
        .onAppear { session.clearAuthFeedback() }
    }
}

struct AuthErrorMessage: View {
    let message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct AuthNoticeMessage: View {
    let message: String?

    var body: some View {
        if let message {
            Label(message, systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tmGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.tmGreen.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct ForgotPasswordView: View {
    @EnvironmentObject private var session: AppSession
    @State private var email = ""

    var body: some View {
        AuthFormLayout(title: "Reset password", subtitle: "Create a local Firebase password-reset link for your account.") {
            AuthTextField(title: "Email", text: $email, icon: "envelope.fill")
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)

            Button {
                Task { await session.sendPasswordReset(email: email) }
            } label: {
                HStack {
                    if session.isAuthWorking {
                        ProgressView()
                    }
                    Label("Create Reset Link", systemImage: "paperplane.fill")
                }
                .authPrimaryButton()
            }
            .disabled(email.isEmpty || session.isAuthWorking)

            AuthNoticeMessage(message: session.authNotice)
            AuthErrorMessage(message: session.authError)
        }
        .navigationTitle("Forgot Password")
        .onAppear { session.clearAuthFeedback() }
    }
}

struct AuthFormLayout<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.tmInk)
                    Text(subtitle)
                        .foregroundStyle(Color.tmSlate)
                }

                VStack(spacing: 14) {
                    content
                }
            }
            .padding(20)
        }
        .background(Color.tmMist.ignoresSafeArea())
    }
}

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.tmGreen)
                .frame(width: 24)
            TextField(title, text: $text)
                .textInputAutocapitalization(.never)
        }
        .authFieldStyle()
    }
}

struct AuthSecureField: View {
    let title: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.tmGreen)
                .frame(width: 24)
            SecureField(title, text: $text)
        }
        .authFieldStyle()
    }
}

extension View {
    func authPrimaryButton() -> some View {
        self
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.tmGreen)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    func authSecondaryButton() -> some View {
        self
            .font(.headline)
            .foregroundStyle(Color.tmGreen)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tmLine, lineWidth: 1))
    }

    func authFieldStyle() -> some View {
        self
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

