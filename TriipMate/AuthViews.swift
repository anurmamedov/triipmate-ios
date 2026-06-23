import SwiftUI

final class AppSession: ObservableObject {
    @Published var isAuthenticated = false
    @Published var activeRole: AppRole = .passenger
}

enum AppRole: String, CaseIterable, Identifiable {
    case passenger
    case driver

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }

    var icon: String {
        self == .driver ? "car.fill" : "person.fill"
    }
}

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
                    Text("Find trusted people going your way and split the cost of long-distance travel.")
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
                session.isAuthenticated = true
            } label: {
                Label("Log In", systemImage: "arrow.right.circle.fill")
                    .authPrimaryButton()
            }
        }
        .navigationTitle("Log In")
    }
}

struct RegisterView: View {
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

            NavigationLink {
                VerificationView(nextStep: .profile)
            } label: {
                Label("Create Account", systemImage: "checkmark.circle.fill")
                    .authPrimaryButton()
            }
        }
        .navigationTitle("Register")
    }
}

struct ForgotPasswordView: View {
    @State private var emailOrPhone = ""

    var body: some View {
        AuthFormLayout(title: "Reset password", subtitle: "Enter your email or phone and we will send a verification code.") {
            AuthTextField(title: "Email or phone", text: $emailOrPhone, icon: "envelope.badge.fill")

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

            AuthTextField(title: "Home city", text: $homeCity, icon: "house.fill")
            AuthTextField(title: "Home state", text: $homeState, icon: "map.fill")
            AuthTextField(title: "Age", text: $age, icon: "calendar")
                .keyboardType(.numberPad)

            Picker("Gender", selection: $gender) {
                Text("Male").tag("Male")
                Text("Female").tag("Female")
            }
            .pickerStyle(.segmented)

            Toggle("Owned car", isOn: $ownsCar)
            AuthTextField(title: "Short bio", text: $bio, icon: "text.quote")

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
        AuthFormLayout(title: "Trust setup", subtitle: "Verification makes shared rides safer and easier to accept.") {
            TrustRow(icon: "phone.badge.checkmark.fill", title: "Phone verification", value: "Complete")
            TrustRow(icon: "person.text.rectangle.fill", title: "Government ID", value: "Add later")
            TrustRow(icon: "car.fill", title: "Driver license", value: "For drivers")
            TrustRow(icon: "cross.case.fill", title: "Emergency contact", value: "Recommended")

            Button {
                session.isAuthenticated = true
            } label: {
                Label("Finish Setup", systemImage: "checkmark.circle.fill")
                    .authPrimaryButton()
            }
        }
        .navigationTitle("Trust")
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
