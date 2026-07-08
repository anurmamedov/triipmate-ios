import SwiftUI
import PhotosUI
import UIKit

private struct PhoneCountry: Identifiable {
    let id: String
    let name: String
    let flag: String
    let dialCode: String
}

private let northAmericanPhoneCountries = [
    PhoneCountry(id: "CA", name: "Canada", flag: "🇨🇦", dialCode: "+1"),
    PhoneCountry(id: "US", name: "United States", flag: "🇺🇸", dialCode: "+1")
]

private let europeanPhoneCountries = [
    PhoneCountry(id: "AT", name: "Austria", flag: "🇦🇹", dialCode: "+43"),
    PhoneCountry(id: "BE", name: "Belgium", flag: "🇧🇪", dialCode: "+32"),
    PhoneCountry(id: "CZ", name: "Czechia", flag: "🇨🇿", dialCode: "+420"),
    PhoneCountry(id: "DK", name: "Denmark", flag: "🇩🇰", dialCode: "+45"),
    PhoneCountry(id: "FI", name: "Finland", flag: "🇫🇮", dialCode: "+358"),
    PhoneCountry(id: "FR", name: "France", flag: "🇫🇷", dialCode: "+33"),
    PhoneCountry(id: "DE", name: "Germany", flag: "🇩🇪", dialCode: "+49"),
    PhoneCountry(id: "GR", name: "Greece", flag: "🇬🇷", dialCode: "+30"),
    PhoneCountry(id: "IE", name: "Ireland", flag: "🇮🇪", dialCode: "+353"),
    PhoneCountry(id: "IT", name: "Italy", flag: "🇮🇹", dialCode: "+39"),
    PhoneCountry(id: "NL", name: "Netherlands", flag: "🇳🇱", dialCode: "+31"),
    PhoneCountry(id: "NO", name: "Norway", flag: "🇳🇴", dialCode: "+47"),
    PhoneCountry(id: "PL", name: "Poland", flag: "🇵🇱", dialCode: "+48"),
    PhoneCountry(id: "PT", name: "Portugal", flag: "🇵🇹", dialCode: "+351"),
    PhoneCountry(id: "RO", name: "Romania", flag: "🇷🇴", dialCode: "+40"),
    PhoneCountry(id: "ES", name: "Spain", flag: "🇪🇸", dialCode: "+34"),
    PhoneCountry(id: "SE", name: "Sweden", flag: "🇸🇪", dialCode: "+46"),
    PhoneCountry(id: "CH", name: "Switzerland", flag: "🇨🇭", dialCode: "+41"),
    PhoneCountry(id: "UA", name: "Ukraine", flag: "🇺🇦", dialCode: "+380"),
    PhoneCountry(id: "GB", name: "United Kingdom", flag: "🇬🇧", dialCode: "+44"),
]

private let southAsianPhoneCountries = [
    PhoneCountry(id: "AF", name: "Afghanistan", flag: "🇦🇫", dialCode: "+93"),
    PhoneCountry(id: "BD", name: "Bangladesh", flag: "🇧🇩", dialCode: "+880"),
    PhoneCountry(id: "BT", name: "Bhutan", flag: "🇧🇹", dialCode: "+975"),
    PhoneCountry(id: "IN", name: "India", flag: "🇮🇳", dialCode: "+91"),
    PhoneCountry(id: "MV", name: "Maldives", flag: "🇲🇻", dialCode: "+960"),
    PhoneCountry(id: "NP", name: "Nepal", flag: "🇳🇵", dialCode: "+977"),
    PhoneCountry(id: "PK", name: "Pakistan", flag: "🇵🇰", dialCode: "+92"),
    PhoneCountry(id: "LK", name: "Sri Lanka", flag: "🇱🇰", dialCode: "+94")
]

private let otherPhoneCountries = [
    PhoneCountry(id: "AU", name: "Australia", flag: "🇦🇺", dialCode: "+61"),
    PhoneCountry(id: "TR", name: "Türkiye", flag: "🇹🇷", dialCode: "+90"),
    PhoneCountry(id: "TM", name: "Turkmenistan", flag: "🇹🇲", dialCode: "+993")
]

private let phoneCountries = northAmericanPhoneCountries
    + europeanPhoneCountries
    + southAsianPhoneCountries
    + otherPhoneCountries

struct ProfileView: View {
    @EnvironmentObject private var session: AppSession
    @State private var isShowingLogoutConfirmation = false
    @State private var isShowingProfileEditor = false

    private var displayName: String {
        guard let profile = session.userProfile else {
            return session.authUser?.email ?? "TriipMate User"
        }

        let name = "\(profile.firstName) \(profile.lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? profile.email : name
    }

    private var displayInitials: String {
        guard let profile = session.userProfile else {
            return initials(from: session.authUser?.email ?? "TU")
        }

        let fullName = "\(profile.firstName) \(profile.lastName)"
        return initials(from: fullName.isEmpty ? profile.email : fullName)
    }

    private var verificationLabel: String {
        guard let profile = session.userProfile else { return "Verification unavailable" }
        if session.activeRole == .driver {
            return profile.isDriverVerified ? "Verified driver" : "Driver verification pending"
        }
        return profile.isIdentityVerified ? "Verified traveler" : "Identity not verified"
    }

    private var verificationIcon: String {
        guard let profile = session.userProfile else { return "questionmark.circle.fill" }
        let isVerified = session.activeRole == .driver ? profile.isDriverVerified : profile.isIdentityVerified
        return isVerified ? "checkmark.seal.fill" : "clock.badge.exclamationmark.fill"
    }

    private var ratingValue: String {
        guard let rating = session.userProfile?.ratingAverage else { return "New" }
        return rating.formatted(.number.precision(.fractionLength(1)))
    }

    private var tripValue: String {
        String(session.userProfile?.completedTripCount ?? 0)
    }

    private var savingsValue: String {
        let cents = session.userProfile?.totalSavingsCents ?? 0
        return (Double(cents) / 100).formatted(
            .currency(code: "USD").precision(.fractionLength(0))
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let error = session.profileError {
                        ProfileStatusBanner(message: error) {
                            Task { await session.refreshProfile() }
                        }
                    }

                    VStack(spacing: 12) {
                        profilePhoto
                            .padding(.bottom, 10)

                        Text(displayName)
                            .font(.title2.bold())
                            .foregroundStyle(Color.tmInk)

                        Label(
                            verificationLabel,
                            systemImage: verificationIcon
                        )
                            .foregroundStyle(Color.tmGreen)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    HStack(spacing: 12) {
                        StatTile(value: ratingValue, label: "Rating", icon: "star.fill")
                        StatTile(value: tripValue, label: "Trips", icon: "car.fill", iconColor: .tmSlate)
                        StatTile(value: savingsValue, label: "Saved")
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        SettingsRow(icon: "person.text.rectangle.fill", title: "Identity and license")
                        SettingsRow(icon: "creditcard.fill", title: "Payment methods")
                        SettingsRow(icon: "bell.fill", title: "Trip alerts")
                        SettingsRow(icon: "questionmark.circle.fill", title: "Support")
                        Button {
                            isShowingLogoutConfirmation = true
                        } label: {
                            SettingsRow(icon: "rectangle.portrait.and.arrow.right.fill", title: "Logout", color: .tmGreen)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 16) {
                        Text(session.activeRole == .driver ? "Driver tools" : "Passenger tools")
                            .font(.headline)
                            .foregroundStyle(Color.tmInk)
                        if session.activeRole == .driver {
                            NavigationLink {
                                VehicleDetailsView()
                            } label: {
                                SettingsRow(icon: "car.fill", title: "Vehicle details")
                            }
                            .buttonStyle(.plain)
                            SettingsRow(icon: "person.2.badge.gearshape.fill", title: "Passenger requests")
                            SettingsRow(icon: "dollarsign.circle.fill", title: "Payout setup")
                        } else {
                            SettingsRow(icon: "ticket.fill", title: "Saved trips")
                            SettingsRow(icon: "clock.arrow.circlepath", title: "Ride history")
                            SettingsRow(icon: "slider.horizontal.3", title: "Travel preferences")
                        }
                    }
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(20)
            }
            .background(Color.tmMist.ignoresSafeArea())
            .overlay {
                if session.userProfile == nil {
                    ProfileUnavailableState(isLoading: session.isProfileLoading) {
                        Task { await session.refreshProfile() }
                    }
                }
            }
            .refreshable {
                await session.refreshProfile()
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                RoleSwitchHeader()
            }
            .alert("Log out?", isPresented: $isShowingLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    session.logout()
                }
            } message: {
                Text("Are you sure you want to log out of TriipMate?")
            }
            .sheet(isPresented: $isShowingProfileEditor) {
                EditProfileInformationView()
                    .environmentObject(session)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .task {
                if session.userProfile == nil {
                    await session.refreshProfile()
                }
            }
        }
    }

    @ViewBuilder
    private var profilePhoto: some View {
        ZStack(alignment: .bottomTrailing) {
            if let data = session.profileImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 118, height: 118)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Avatar(initials: displayInitials)
                    .scaleEffect(1.65)
                    .frame(width: 118, height: 118)
            }

            Button {
                isShowingProfileEditor = true
            } label: {
                Image(systemName: "pencil")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.tmGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit profile")
            .offset(x: 9, y: 9)
        }
    }

    private func initials(from text: String) -> String {
        let words = text
            .split { !$0.isLetter && !$0.isNumber }
            .prefix(2)
        let value = words.compactMap(\.first).map(String.init).joined()
        return value.isEmpty ? "TM" : value.uppercased()
    }
}

struct VehicleDetailsView: View {
    @EnvironmentObject private var session: AppSession
    @State private var editingVehicleID: String?
    @State private var make = ""
    @State private var model = ""
    @State private var year = ""
    @State private var powerType = "Fuel"
    @State private var bodyType = "Sedan"
    @State private var validationMessage: String?

    var body: some View {
        Form {
            if !session.savedVehicles.isEmpty {
                Section("Saved vehicles") {
                    ForEach(session.savedVehicles) { vehicle in
                        Button {
                            load(vehicle)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "car.fill")
                                    .foregroundStyle(Color.tmGreen)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(vehicle.displayName)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Color.tmInk)
                                    Text("\(vehicle.powerType) · \(vehicle.bodyType)")
                                        .font(.caption)
                                        .foregroundStyle(Color.tmSlate)
                                }
                                Spacer()
                                if editingVehicleID == vehicle.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.tmGreen)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section(editingVehicleID == nil ? "Add vehicle" : "Edit vehicle") {
                TextField("Car make", text: $make)
                    .textContentType(.organizationName)
                TextField("Car model", text: $model)
                TextField("Car year", text: $year)
                    .keyboardType(.numberPad)
                    .onChange(of: year) { value in
                        year = String(value.filter { $0.isNumber }.prefix(4))
                    }
                Picker("Power type", selection: $powerType) {
                    Text("Fuel").tag("Fuel")
                    Text("Electric").tag("Electric")
                    Text("Hybrid").tag("Hybrid")
                }
                Picker("Body type", selection: $bodyType) {
                    Text("Sedan").tag("Sedan")
                    Text("SUV").tag("SUV")
                    Text("Van").tag("Van")
                    Text("Truck").tag("Truck")
                    Text("Hatchback").tag("Hatchback")
                }
            }

            if let message = validationMessage ?? session.authError {
                Section {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    save()
                } label: {
                    HStack {
                        Spacer()
                        if session.isVehicleWorking {
                            ProgressView()
                        } else {
                            Label(editingVehicleID == nil ? "Save vehicle" : "Update vehicle", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                        }
                        Spacer()
                    }
                }
                .disabled(session.isVehicleWorking)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.tmMist)
        .navigationTitle("Vehicle details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if editingVehicleID != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add New") { clearForm() }
                }
            }
        }
        .tint(Color.tmGreen)
    }

    private func load(_ vehicle: SavedVehicle) {
        editingVehicleID = vehicle.id
        make = vehicle.make
        model = vehicle.model
        year = vehicle.year
        powerType = vehicle.powerType
        bodyType = vehicle.bodyType
        validationMessage = nil
        session.authError = nil
    }

    private func clearForm() {
        editingVehicleID = nil
        make = ""
        model = ""
        year = ""
        powerType = "Fuel"
        bodyType = "Sedan"
        validationMessage = nil
        session.authError = nil
    }

    private func save() {
        let cleanMake = make.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanMake.isEmpty, !cleanModel.isEmpty, year.count == 4 else {
            validationMessage = "Enter the vehicle make, model, and four-digit year."
            return
        }

        validationMessage = nil
        let vehicle = SavedVehicle(
            id: editingVehicleID ?? UUID().uuidString,
            make: cleanMake,
            model: cleanModel,
            year: year,
            powerType: powerType,
            bodyType: bodyType
        )
        Task {
            if await session.saveVehicle(vehicle) {
                load(vehicle)
            }
        }
    }
}

struct EditProfileInformationView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var selectedCountryID = "CA"
    @State private var phone = ""
    @State private var pendingPhotoData: Data?
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var isShowingPhotoSource = false
    @State private var isShowingImagePicker = false
    @State private var validationMessage: String?

    private var selectedCountry: PhoneCountry {
        phoneCountries.first { $0.id == selectedCountryID } ?? phoneCountries[0]
    }

    private var displayedPhotoData: Data? {
        pendingPhotoData ?? session.profileImageData
    }

    private var isSaving: Bool {
        session.isProfileWorking || session.isProfilePhotoWorking
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 10) {
                        ZStack(alignment: .bottomTrailing) {
                            profilePreview

                            Button {
                                isShowingPhotoSource = true
                            } label: {
                                Image(systemName: "camera.fill")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.tmGreen)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.white, lineWidth: 2)
                                    }
                            }
                            .buttonStyle(.plain)
                            .offset(x: 7, y: 7)
                            .accessibilityLabel("Change profile photo")
                        }

                        Text("Profile photo")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.tmSlate)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }

                Section("Personal information") {
                    TextField("First name", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Last name", text: $lastName)
                        .textContentType(.familyName)
                }

                Section("Contact information") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    HStack(spacing: 12) {
                        Menu {
                            Section("North America") {
                                ForEach(northAmericanPhoneCountries) { country in
                                    countryButton(country)
                                }
                            }
                            Section("Europe") {
                                ForEach(europeanPhoneCountries) { country in
                                    countryButton(country)
                                }
                            }
                            Section("Southern Asia") {
                                ForEach(southAsianPhoneCountries) { country in
                                    countryButton(country)
                                }
                            }
                            Section("Other") {
                                ForEach(otherPhoneCountries) { country in
                                    countryButton(country)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(selectedCountry.flag)
                                Text(selectedCountry.dialCode)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color.tmInk)
                                Image(systemName: "chevron.down")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color.tmSlate)
                            }
                            .frame(minWidth: 86, alignment: .leading)
                            .contentShape(Rectangle())
                        }

                        Divider()
                            .frame(height: 28)

                        TextField("Phone number", text: $phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .onChange(of: phone) { newValue in
                                phone = String(newValue.filter { $0.isNumber }.prefix(15))
                            }
                    }
                }

                if let message = validationMessage ?? session.profileError {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.tmMist)
            .navigationTitle("Personal information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save").bold()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear(perform: loadProfile)
            .confirmationDialog("Profile photo", isPresented: $isShowingPhotoSource) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") {
                        imagePickerSource = .camera
                        isShowingImagePicker = true
                    }
                }
                Button("Choose from Photo Library") {
                    imagePickerSource = .photoLibrary
                    isShowingImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ProfileImagePicker(sourceType: imagePickerSource, imageData: $pendingPhotoData)
                    .ignoresSafeArea()
            }
        }
        .tint(Color.tmGreen)
    }

    @ViewBuilder
    private var profilePreview: some View {
        if let data = displayedPhotoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 104, height: 104)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Avatar(initials: initials)
                .scaleEffect(1.5)
                .frame(width: 104, height: 104)
        }
    }

    private var initials: String {
        let letters = [firstName.first, lastName.first].compactMap { $0 }
        return letters.isEmpty ? "TM" : String(letters).uppercased()
    }

    private func countryButton(_ country: PhoneCountry) -> some View {
        Button {
            selectedCountryID = country.id
        } label: {
            Text("\(country.flag) \(country.name)  \(country.dialCode)")
        }
    }

    private func loadProfile() {
        guard let profile = session.userProfile else { return }
        firstName = profile.firstName
        lastName = profile.lastName
        email = profile.email
        let phoneParts = profile.phone.split(separator: " ", maxSplits: 1).map(String.init)
        if let savedCode = phoneParts.first,
           let savedCountry = phoneCountries.first(where: { $0.dialCode == savedCode }) {
            selectedCountryID = savedCountry.id
            phone = phoneParts.count > 1 ? phoneParts[1] : ""
        } else {
            phone = profile.phone
        }
        session.profileError = nil
    }

    private func save() {
        let cleanFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let formattedPhone = cleanPhone.isEmpty ? "" : "\(selectedCountry.dialCode) \(cleanPhone)"

        guard !cleanFirstName.isEmpty, !cleanLastName.isEmpty else {
            validationMessage = "First and last name are required."
            return
        }
        guard cleanEmail.contains("@") else {
            validationMessage = "Enter a valid email address."
            return
        }

        validationMessage = nil
        Task {
            await session.updateProfile(
                firstName: cleanFirstName,
                lastName: cleanLastName,
                email: cleanEmail,
                phone: formattedPhone
            )
            guard session.profileError == nil else { return }

            if let pendingPhotoData {
                await session.updateProfilePhoto(pendingPhotoData)
            }
            if session.profileError == nil {
                dismiss()
            }
        }
    }
}

private struct ProfileStatusBanner: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(Color.tmAmber)
            Text(message)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.tmInk)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: retry) {
                Image(systemName: "arrow.clockwise")
                    .font(.subheadline.weight(.bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.tmGreen)
            .accessibilityLabel("Retry profile")
        }
        .padding(12)
        .background(Color.tmAmber.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ProfileUnavailableState: View {
    let isLoading: Bool
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            if isLoading {
                ProgressView()
                    .tint(Color.tmGreen)
                Text("Loading your profile...")
                    .foregroundStyle(Color.tmSlate)
            } else {
                Image(systemName: "person.crop.circle.badge.exclamationmark.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Color.tmSlate)
                Text("Profile unavailable")
                    .font(.headline)
                    .foregroundStyle(Color.tmInk)
                Text("Check the local Firebase server and try again.")
                    .font(.subheadline)
                    .foregroundStyle(Color.tmSlate)
                    .multilineTextAlignment(.center)
                Button(action: retry) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(Color.tmGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
        .background(Color.tmMist)
    }
}

private struct ProfileImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: ProfileImagePicker

        init(parent: ProfileImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            parent.imageData = image?.jpegData(compressionQuality: 0.82)
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var icon: String? = nil
    var iconColor = Color.tmAmber

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(iconColor)
                }
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(Color.tmInk)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.tmSlate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var color = Color.tmGreen

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(title)
                .foregroundStyle(Color.tmInk)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.tmSlate)
        }
    }
}
