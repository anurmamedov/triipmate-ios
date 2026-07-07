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
            AuthSecureField(title: "Password", text: $password, icon: "lock.fill")

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
            AuthTextField(title: "Phone number", text: $phone, icon: "phone.fill")
            AuthSecureField(title: "Password", text: $password, icon: "lock.fill")
            AuthSecureField(title: "Confirm password", text: $confirmPassword, icon: "lock.shield.fill")

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
            .disabled(email.isEmpty || password.isEmpty || confirmPassword.isEmpty || session.isAuthWorking)

            AuthErrorMessage(message: session.authError)
        }
        .navigationTitle("Register")
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

struct ForgotPasswordView: View {
    @State private var email = ""

    var body: some View {
        AuthFormLayout(title: "Reset password", subtitle: "Enter your email and we will send a reset code.") {
            AuthTextField(title: "Email", text: $email, icon: "envelope.fill")

            NavigationLink {
                VerificationView(nextStep: .login)
            } label: {
                Label("Send Code", systemImage: "paperplane.fill")
                    .authPrimaryButton()
            }
        }
        .navigationTitle("Forgot Password")
    }
}

enum VerificationNextStep {
    case profile
    case login
}

struct VerificationView: View {
    let nextStep: VerificationNextStep
    @EnvironmentObject private var session: AppSession
    @State private var code = ""

    var body: some View {
        AuthFormLayout(title: "Enter verification code", subtitle: "Use the code sent to your phone.") {
            AuthTextField(title: "6-digit code", text: $code, icon: "number")
                .keyboardType(.numberPad)

            if nextStep == .profile {
                NavigationLink {
                    CreateProfileView()
                } label: {
                    Label("Verify and Continue", systemImage: "checkmark.seal.fill")
                        .authPrimaryButton()
                }
            } else {
                Button {
                    session.isAuthenticated = true
                } label: {
                    Label("Verify and Log In", systemImage: "checkmark.seal.fill")
                        .authPrimaryButton()
                }
            }
        }
        .navigationTitle("Verification")
    }
}

struct CreateProfileView: View {
    @State private var homeCity = ""
    @State private var homeState = ""
    @State private var gender = "Male"
    @State private var age = ""
    @State private var bio = ""
    @State private var ownsCar = false
    @State private var prefersQuietRide = true
    @State private var allowsLuggage = true

    var body: some View {
        AuthFormLayout(title: "Create your profile", subtitle: "Add details that help drivers and passengers feel comfortable.") {
            VStack(spacing: 10) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 58))
                    .foregroundStyle(Color.tmGreen)
                Text("Add Profile Photo")
                    .font(.headline)
                    .foregroundStyle(Color.tmInk)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            AuthSectionTitle("Basic profile")
            AuthTextField(title: "Home city", text: $homeCity, icon: "house.fill")
            AuthTextField(title: "Home state", text: $homeState, icon: "map.fill")
            AuthTextField(title: "Age", text: $age, icon: "calendar")
                .keyboardType(.numberPad)
            Picker("Gender", selection: $gender) {
                Text("Male").tag("Male")
                Text("Female").tag("Female")
            }
            .pickerStyle(.segmented)
            AuthTextField(title: "Short bio", text: $bio, icon: "text.quote")

            AuthSectionTitle("Travel preferences")
            Toggle("I may offer rides as a driver", isOn: $ownsCar)
            Toggle("Prefer quiet rides", isOn: $prefersQuietRide)
            Toggle("Usually have luggage", isOn: $allowsLuggage)

            NavigationLink {
                TrustSetupView()
            } label: {
                Label("Continue", systemImage: "arrow.right.circle.fill")
                    .authPrimaryButton()
            }
        }
        .navigationTitle("Profile")
    }
}

struct TrustSetupView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        AuthFormLayout(title: "Safety & Verification", subtitle: "Verification makes shared rides safer and easier to accept.") {
            TrustRow(icon: "phone.badge.checkmark.fill", title: "Phone verification", value: "Complete")
            TrustRow(icon: "person.text.rectangle.fill", title: "Government ID", value: "Add later")
            TrustRow(icon: "car.fill", title: "Driver license", value: "For drivers")
            TrustRow(icon: "cross.case.fill", title: "Emergency contact", value: "Recommended")

            NavigationLink {
                ModeSelectionView()
            } label: {
                Label("Choose Mode", systemImage: "arrow.right.circle.fill")
                    .authPrimaryButton()
            }
        }
        .navigationTitle("Safety")
    }
}

struct ModeSelectionView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        AuthFormLayout(title: "What do you want to do today?", subtitle: "You can switch between passenger and driver mode anytime.") {
            Button {
                session.activeRole = .passenger
                session.isAuthenticated = true
            } label: {
                ModeChoiceRow(icon: "person.fill", title: "Find a ride", detail: "Search drivers, request a seat, and message about pickup.")
            }
            .buttonStyle(.plain)

            Button {
                session.activeRole = .driver
                session.isAuthenticated = true
            } label: {
                ModeChoiceRow(icon: "car.fill", title: "Offer a ride", detail: "Post your trip, review requests, and manage open seats.")
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Choose Mode")
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

struct TrustRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.tmGreen)
                .frame(width: 28)
            Text(title)
                .foregroundStyle(Color.tmInk)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tmSlate)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AuthSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color.tmInk)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }
}

struct ModeChoiceRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.tmGreen)
                .frame(width: 44, height: 44)
                .background(Color.tmCloud)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.tmInk)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.tmSlate)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.tmSlate)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

