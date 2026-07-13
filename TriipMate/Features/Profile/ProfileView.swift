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
        return CurrencySupport.format(cents: cents, countryCode: session.userProfile?.countryCode)
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
                        NavigationLink {
                            IdentityAndLicenseView()
                        } label: {
                            SettingsRow(icon: "person.text.rectangle.fill", title: "Identity and license")
                        }
                        .buttonStyle(.plain)
                        NavigationLink {
                            PaymentMethodsView()
                        } label: {
                            SettingsRow(icon: "creditcard.fill", title: "Payment methods")
                        }
                        .buttonStyle(.plain)
                        NavigationLink {
                            TripAlertsView()
                        } label: {
                            SettingsRow(icon: "bell.fill", title: "Trip alerts")
                        }
                        .buttonStyle(.plain)
                        NavigationLink {
                            SupportCenterView()
                        } label: {
                            SettingsRow(icon: "questionmark.circle.fill", title: "Support")
                        }
                        .buttonStyle(.plain)
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
                            NavigationLink {
                                DriverPassengerRequestsToolView()
                            } label: {
                                SettingsRow(icon: "person.2.badge.gearshape.fill", title: "Passenger requests")
                            }
                            .buttonStyle(.plain)
                            NavigationLink {
                                PayoutSetupView()
                            } label: {
                                SettingsRow(icon: "dollarsign.circle.fill", title: "Payout setup")
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                PassengerSavedTripsToolView()
                            } label: {
                                SettingsRow(icon: "ticket.fill", title: "Saved trips")
                            }
                            .buttonStyle(.plain)
                            NavigationLink {
                                PassengerRideHistoryToolView()
                            } label: {
                                SettingsRow(icon: "clock.arrow.circlepath", title: "Ride history")
                            }
                            .buttonStyle(.plain)
                            NavigationLink {
                                TravelPreferencesView()
                            } label: {
                                SettingsRow(icon: "slider.horizontal.3", title: "Travel preferences")
                            }
                            .buttonStyle(.plain)
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
                    .foregroundStyle(Color.tmGreen)
                    .frame(width: 36, height: 36)
                    .background(Color.tmCloud)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white, lineWidth: 2)
                    )
                    .shadow(color: Color.tmGreen.opacity(0.14), radius: 8, y: 3)
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
    @State private var vehicleToDelete: SavedVehicle?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !session.savedVehicles.isEmpty {
                    vehicleSectionTitle("Saved vehicles")
                    VStack(spacing: 12) {
                        ForEach(session.savedVehicles) { vehicle in
                            ProfileVehicleCard(
                                vehicle: vehicle,
                                isEditing: editingVehicleID == vehicle.id,
                                isWorking: session.isVehicleWorking,
                                onSelect: { load(vehicle) },
                                onMakeDefault: {
                                    Task { await session.setDefaultVehicle(vehicle) }
                                },
                                onDelete: { vehicleToDelete = vehicle }
                            )
                        }
                    }
                }

                vehicleSectionTitle(editingVehicleID == nil ? "Add vehicle" : "Edit vehicle")
                vehicleFormCard

                if let message = validationMessage ?? session.authError {
                    VehicleNoticeCard(message: message)
                }
            }
            .padding(20)
            .padding(.bottom, 94)
        }
        .background(Color.tmMist.ignoresSafeArea())
        .navigationTitle("Vehicle details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if editingVehicleID != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        clearForm()
                    } label: {
                        Label("Add New", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            vehicleSaveBar
        }
        .alert(item: $vehicleToDelete) { vehicle in
            Alert(
                title: Text("Delete vehicle?"),
                message: Text("This removes \(vehicle.displayName) from your saved vehicles."),
                primaryButton: .destructive(Text("Delete")) {
                    Task {
                        if await session.deleteVehicle(vehicle), editingVehicleID == vehicle.id {
                            clearForm()
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .tint(Color.tmGreen)
        .onAppear {
            session.authError = nil
        }
    }

    private func vehicleSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color.tmInk)
    }

    private var vehicleFormCard: some View {
        VStack(spacing: 12) {
            VehicleProfileInput(title: "Make", placeholder: "Toyota", text: $make)
                .textContentType(.organizationName)
            VehicleProfileInput(title: "Model", placeholder: "Corolla", text: $model)
            VehicleProfileInput(title: "Year", placeholder: "2022", text: $year, keyboardType: .numberPad)
                .onChange(of: year) { value in
                    year = String(value.filter { $0.isNumber }.prefix(4))
                }

            HStack(spacing: 10) {
                VehicleProfileMenu(title: "Power", selection: $powerType, options: ["Fuel", "Electric", "Hybrid"], icon: "fuelpump.fill")
                VehicleProfileMenu(title: "Body", selection: $bodyType, options: ["Sedan", "SUV", "Van", "Truck", "Hatchback"], icon: "rectangle.3.group.fill")
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.tmLine, lineWidth: 1)
        }
    }

    private var vehicleSaveBar: some View {
        Button {
            save()
        } label: {
            if session.isVehicleWorking {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            } else {
                Label(editingVehicleID == nil ? "Save vehicle" : "Update vehicle", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(Color.tmGreen)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.tmGreen.opacity(0.18), radius: 10, y: 5)
        .disabled(session.isVehicleWorking)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background {
            Rectangle()
                .fill(Color.tmMist.opacity(0.96))
                .ignoresSafeArea()
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.tmLine.opacity(0.8))
                        .frame(height: 1)
                }
        }
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
        let isDefault = session.savedVehicles.first(where: { $0.id == editingVehicleID })?.isDefault ?? session.savedVehicles.isEmpty
        let vehicle = SavedVehicle(
            id: editingVehicleID ?? UUID().uuidString,
            make: cleanMake,
            model: cleanModel,
            year: year,
            powerType: powerType,
            bodyType: bodyType,
            isDefault: isDefault
        )
        Task {
            if await session.saveVehicle(vehicle) {
                load(vehicle)
            }
        }
    }
}

private struct ProfileVehicleCard: View {
    let vehicle: SavedVehicle
    let isEditing: Bool
    let isWorking: Bool
    let onSelect: () -> Void
    let onMakeDefault: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.headline)
                        .foregroundStyle(isEditing ? .white : Color.tmGreen)
                        .frame(width: 40, height: 40)
                        .background(isEditing ? Color.tmGreen : Color.tmGreen.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(vehicle.displayName)
                                .font(.headline)
                                .foregroundStyle(Color.tmInk)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                            if vehicle.isDefault {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.tmGreen)
                            }
                        }
                        Text("\(vehicle.powerType) · \(vehicle.bodyType)")
                            .font(.caption)
                            .foregroundStyle(Color.tmSlate)
                    }

                    Spacer()

                    if isEditing {
                        Text("Editing")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.tmGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.tmGreen.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Button(action: onMakeDefault) {
                    Label(vehicle.isDefault ? "Default vehicle" : "Make default", systemImage: vehicle.isDefault ? "checkmark.circle.fill" : "circle")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(vehicle.isDefault ? Color.tmGreen : Color.tmInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(vehicle.isDefault ? Color.tmGreen.opacity(0.12) : Color.tmCloud)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(vehicle.isDefault || isWorking)

                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.red)
                        .frame(width: 44, height: 36)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(isWorking)
                .accessibilityLabel("Delete vehicle")
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isEditing ? Color.tmGreen.opacity(0.45) : Color.tmLine, lineWidth: 1)
        }
    }
}

private struct VehicleProfileInput: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.tmSlate)
            TextField(placeholder, text: $text)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.tmInk)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(Color.tmMist)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct VehicleProfileMenu: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    let icon: String

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    selection = option
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Color.tmGreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.tmSlate)
                    Text(selection)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.tmInk)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.tmSlate)
            }
            .padding(12)
            .background(Color.tmMist)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct VehicleNoticeCard: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
                                    .foregroundStyle(Color.tmGreen)
                                    .frame(width: 36, height: 36)
                                    .background(Color.tmCloud)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.white, lineWidth: 2)
                                    }
                                    .shadow(color: Color.tmGreen.opacity(0.14), radius: 8, y: 3)
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
        selectedCountryID = profile.countryCode
        let phoneParts = profile.phone.split(separator: " ", maxSplits: 1).map(String.init)
        if let savedCode = phoneParts.first,
           let savedCountry = phoneCountries.first(where: { $0.id == profile.countryCode && $0.dialCode == savedCode })
            ?? phoneCountries.first(where: { $0.id == profile.countryCode })
            ?? phoneCountries.first(where: { $0.dialCode == savedCode }) {
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
                phone: formattedPhone,
                countryCode: selectedCountry.id
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

private struct IdentityAndLicenseView: View {
    @EnvironmentObject private var session: AppSession
    @AppStorage("identityDocumentType") private var documentType = "Driver license"
    @AppStorage("identityDocumentNumber") private var documentNumber = ""
    @AppStorage("identityLicenseState") private var licenseState = ""

    private var isDriver: Bool { session.activeRole == .driver }
    private var profile: UserProfile? { session.userProfile }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ProfileToolHeroCard(
                    icon: isDriver ? "checkmark.shield.fill" : "person.text.rectangle.fill",
                    title: isDriver ? "Driver verification" : "Identity verification",
                    detail: isDriver ? "Confirm your license before accepting passengers." : "Confirm your identity before booking more confidently.",
                    status: isDriver ? driverStatus : travelerStatus,
                    statusTint: isDriver && profile?.isDriverVerified == true ? .tmGreen : .tmAmber
                )

                ProfileToolCard(title: "Verification steps") {
                    VerificationStepRow(icon: "person.crop.circle.fill", title: "Personal information", detail: profileDisplayName, isComplete: profile != nil)
                    VerificationStepRow(icon: "phone.fill", title: "Phone number", detail: profile?.phone.isEmpty == false ? profile?.phone ?? "" : "Add a phone number", isComplete: profile?.phone.isEmpty == false)
                    VerificationStepRow(icon: "doc.text.viewfinder.fill", title: documentType, detail: documentNumber.isEmpty ? "Add document details" : "Ending \(String(documentNumber.suffix(4)))", isComplete: !documentNumber.isEmpty)
                    if isDriver {
                        VerificationStepRow(icon: "car.fill", title: "Driver license region", detail: licenseState.isEmpty ? "Add issuing state or province" : licenseState, isComplete: !licenseState.isEmpty)
                    }
                }

                ProfileToolCard(title: "Document details") {
                    Picker("Document", selection: $documentType) {
                        Text("Driver license").tag("Driver license")
                        Text("Passport").tag("Passport")
                        Text("Provincial ID").tag("Provincial ID")
                        Text("State ID").tag("State ID")
                    }
                    .pickerStyle(.menu)

                    ProfileToolTextField(title: "Document number", placeholder: "Enter document number", text: $documentNumber)
                    if isDriver {
                        ProfileToolTextField(title: "State or province", placeholder: "Ontario, CA, PA...", text: $licenseState)
                    }
                }

                ProfileToolNotice(
                    icon: "lock.shield.fill",
                    title: "Local verification only",
                    detail: "These details are saved on this device for local testing. Production verification will need a secure KYC provider before real approvals."
                )
            }
            .padding(20)
        }
        .background(Color.tmMist.ignoresSafeArea())
        .navigationTitle("Identity and license")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color.tmGreen)
    }

    private var travelerStatus: String {
        profile?.isIdentityVerified == true ? "Verified traveler" : "Identity not verified"
    }

    private var driverStatus: String {
        profile?.isDriverVerified == true ? "Verified driver" : "Driver verification pending"
    }

    private var profileDisplayName: String {
        guard let profile else { return "Profile required" }
        let name = "\(profile.firstName) \(profile.lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? profile.email : name
    }
}

private struct PaymentMethodsView: View {
    @AppStorage("paymentCardNickname") private var cardNickname = ""
    @AppStorage("paymentLastFour") private var lastFour = ""
    @AppStorage("paymentAutoReceipts") private var autoReceipts = true
    @AppStorage("paymentDefaultMethod") private var defaultMethod = "Card"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ProfileToolHeroCard(
                    icon: "creditcard.fill",
                    title: "Payment methods",
                    detail: "Keep a preferred way to pay for accepted rides.",
                    status: lastFour.isEmpty ? "No payment method added" : "\(defaultMethod) ending \(lastFour)",
                    statusTint: lastFour.isEmpty ? .tmAmber : .tmGreen
                )

                ProfileToolCard(title: "Default method") {
                    Picker("Method", selection: $defaultMethod) {
                        Text("Card").tag("Card")
                        Text("Apple Pay").tag("Apple Pay")
                        Text("Cash").tag("Cash")
                    }
                    .pickerStyle(.segmented)

                    ProfileToolTextField(title: "Card nickname", placeholder: "Personal, Business...", text: $cardNickname)
                    ProfileToolTextField(title: "Last 4 digits", placeholder: "1234", text: $lastFour, keyboardType: .numberPad)
                        .onChange(of: lastFour) { value in
                            lastFour = String(value.filter { $0.isNumber }.prefix(4))
                        }
                    Toggle("Email receipts automatically", isOn: $autoReceipts)
                        .tint(Color.tmGreen)
                }

                ProfileToolNotice(
                    icon: "shield.lefthalf.filled",
                    title: "Payments are not live yet",
                    detail: "This prepares the app flow. Real card storage should use Stripe, Apple Pay, or another PCI-compliant payment provider."
                )
            }
            .padding(20)
        }
        .background(Color.tmMist.ignoresSafeArea())
        .navigationTitle("Payment methods")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TripAlertsView: View {
    @AppStorage("alertRideRequests") private var rideRequests = true
    @AppStorage("alertDriverDecisions") private var driverDecisions = true
    @AppStorage("alertMessages") private var messages = true
    @AppStorage("alertDepartureReminder") private var departureReminder = true
    @AppStorage("alertReminderMinutes") private var reminderMinutes = 60.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ProfileToolHeroCard(
                    icon: "bell.badge.fill",
                    title: "Trip alerts",
                    detail: "Choose what TriipMate should remind you about.",
                    status: "\(enabledCount) alerts enabled",
                    statusTint: enabledCount == 0 ? .tmAmber : .tmGreen
                )

                ProfileToolCard(title: "Notifications") {
                    Toggle("Passenger requests", isOn: $rideRequests)
                    Toggle("Accept and decline updates", isOn: $driverDecisions)
                    Toggle("New messages", isOn: $messages)
                    Toggle("Departure reminder", isOn: $departureReminder)
                    if departureReminder {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Reminder time")
                                Spacer()
                                Text("\(Int(reminderMinutes)) min before")
                                    .foregroundStyle(Color.tmSlate)
                            }
                            Slider(value: $reminderMinutes, in: 15...180, step: 15)
                                .tint(Color.tmGreen)
                        }
                    }
                }
                .tint(Color.tmGreen)

                ProfileToolNotice(
                    icon: "iphone.gen3.radiowaves.left.and.right",
                    title: "Local settings",
                    detail: "These preferences are ready for the app. Push notifications will need APNs and Firebase Cloud Messaging later."
                )
            }
            .padding(20)
        }
        .background(Color.tmMist.ignoresSafeArea())
        .navigationTitle("Trip alerts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var enabledCount: Int {
        [rideRequests, driverDecisions, messages, departureReminder].filter { $0 }.count
    }
}

private struct SupportCenterView: View {
    @State private var selectedTopic = "Ride issue"
    @State private var message = ""
    @State private var didSend = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ProfileToolHeroCard(
                    icon: "questionmark.circle.fill",
                    title: "Support",
                    detail: "Get help with rides, payments, safety, or your account.",
                    status: didSend ? "Support request saved" : "Usually replies within 24 hours",
                    statusTint: didSend ? .tmGreen : .tmSlate
                )

                ProfileToolCard(title: "Quick help") {
                    SupportActionRow(icon: "car.fill", title: "Ride problem", detail: "Driver, passenger, route, or schedule issue")
                    SupportActionRow(icon: "creditcard.fill", title: "Payment help", detail: "Charges, payouts, receipts, or refunds")
                    SupportActionRow(icon: "shield.fill", title: "Safety concern", detail: "Report unsafe behavior or suspicious activity")
                }

                ProfileToolCard(title: "Contact support") {
                    Picker("Topic", selection: $selectedTopic) {
                        Text("Ride issue").tag("Ride issue")
                        Text("Payment").tag("Payment")
                        Text("Safety").tag("Safety")
                        Text("Account").tag("Account")
                    }
                    .pickerStyle(.menu)

                    TextField("Describe what happened", text: $message, axis: .vertical)
                        .lineLimit(4...7)
                        .padding(12)
                        .background(Color.tmMist)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button {
                        didSend = true
                        message = ""
                    } label: {
                        Label("Send request", systemImage: "paperplane.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.tmSlate.opacity(0.45) : Color.tmGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(20)
        }
        .background(Color.tmMist.ignoresSafeArea())
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DriverPassengerRequestsToolView: View {
    @EnvironmentObject private var session: AppSession

    private var pendingRequests: [JoinRideRequest] {
        session.driverRideRequests.sorted { $0.createdAt.date > $1.createdAt.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ProfileToolHeroCard(
                    icon: "person.2.badge.gearshape.fill",
                    title: "Passenger requests",
                    detail: "Review requests from passengers and decide who joins your rides.",
                    status: pendingRequests.isEmpty ? "No requests waiting" : "\(pendingRequests.count) request\(pendingRequests.count == 1 ? "" : "s")",
                    statusTint: pendingRequests.isEmpty ? .tmSlate : .tmGreen
                )

                if session.isDriverRequestsLoading && pendingRequests.isEmpty {
                    ProgressView()
                        .tint(Color.tmGreen)
                        .padding(.top, 24)
                } else if pendingRequests.isEmpty {
                    PassengerToolEmptyState(
                        icon: "person.2.slash.fill",
                        title: "No passenger requests yet",
                        detail: "New passenger requests for your posted rides will appear here."
                    )
                } else {
                    ForEach(pendingRequests) { request in
                        DriverRequestProfileCard(
                            request: request,
                            ride: session.driverRides.first(where: { $0.id == request.rideId }),
                            isWorking: session.isRideRequestWorking,
                            onAccept: {
                                Task { await session.acceptRideRequest(request) }
                            },
                            onDecline: {
                                Task { await session.declineRideRequest(request) }
                            }
                        )
                    }
                }
            }
            .padding(20)
        }
        .background(Color.tmMist.ignoresSafeArea())
        .navigationTitle("Passenger requests")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await session.loadDriverRideRequests()
        }
        .refreshable {
            await session.loadDriverRideRequests()
        }
    }
}

private struct PayoutSetupView: View {
    @AppStorage("payoutAccountName") private var accountName = ""
    @AppStorage("payoutInstitution") private var institution = ""
    @AppStorage("payoutLastFour") private var lastFour = ""
    @AppStorage("payoutFrequency") private var frequency = "Weekly"
    @AppStorage("payoutTaxReady") private var taxReady = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ProfileToolHeroCard(
                    icon: "dollarsign.circle.fill",
                    title: "Payout setup",
                    detail: "Add where driver earnings should be sent once payments are live.",
                    status: lastFour.isEmpty ? "Payout account not added" : "\(frequency) payout ending \(lastFour)",
                    statusTint: lastFour.isEmpty ? .tmAmber : .tmGreen
                )

                ProfileToolCard(title: "Bank details") {
                    ProfileToolTextField(title: "Account holder", placeholder: "Full legal name", text: $accountName)
                    ProfileToolTextField(title: "Bank or institution", placeholder: "TD, Chase, RBC...", text: $institution)
                    ProfileToolTextField(title: "Account last 4 digits", placeholder: "1234", text: $lastFour, keyboardType: .numberPad)
                        .onChange(of: lastFour) { value in
                            lastFour = String(value.filter { $0.isNumber }.prefix(4))
                        }
                    Picker("Frequency", selection: $frequency) {
                        Text("Weekly").tag("Weekly")
                        Text("After each trip").tag("After each trip")
                        Text("Monthly").tag("Monthly")
                    }
                    .pickerStyle(.menu)
                    Toggle("Tax information ready", isOn: $taxReady)
                        .tint(Color.tmGreen)
                }

                ProfileToolNotice(
                    icon: "building.columns.fill",
                    title: "Payouts are not live yet",
                    detail: "Production payouts should use a provider such as Stripe Connect before real driver earnings are processed."
                )
            }
            .padding(20)
        }
        .background(Color.tmMist.ignoresSafeArea())
        .navigationTitle("Payout setup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DriverRequestProfileCard: View {
    let request: JoinRideRequest
    let ride: MarketplaceRide?
    let isWorking: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void

    private var canDecide: Bool { request.status == .pending }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Avatar(initials: initials(for: request.passengerDisplayName))
                    .scaleEffect(0.72)
                    .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.passengerDisplayName)
                        .font(.headline)
                        .foregroundStyle(Color.tmInk)
                    Text("\(request.seatsRequested) seat\(request.seatsRequested == 1 ? "" : "s") • \(request.createdAt.date.profileDateLabel)")
                        .font(.caption)
                        .foregroundStyle(Color.tmSlate)
                }

                Spacer()

                Text(request.status.profileDisplayTitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(request.status.profileTint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(request.status.profileTint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 8) {
                Label(routeTitle, systemImage: "point.topleft.down.curvedto.point.bottomright.up.fill")
                Label(request.pickupNote.emptyFallback("Pickup not added"), systemImage: "location.fill")
                Label(request.dropoffNote.emptyFallback("Drop-off not added"), systemImage: "mappin.and.ellipse")
                Label(request.message.emptyFallback("No passenger message."), systemImage: "text.bubble.fill")
            }
            .font(.subheadline)
            .foregroundStyle(Color.tmSlate)

            HStack(spacing: 10) {
                Button(action: onDecline) {
                    Label("Decline", systemImage: "xmark.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(canDecide ? Color.tmSlate : Color.tmSlate.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.tmCloud)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(!canDecide || isWorking)

                Button(action: onAccept) {
                    Label("Accept", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(canDecide ? Color.tmGreen : Color.tmSlate.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(!canDecide || isWorking)
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.tmLine, lineWidth: 1)
        }
    }

    private var routeTitle: String {
        guard let ride else { return "Ride unavailable" }
        return "\(ride.from.displayName) -> \(ride.to.displayName)"
    }

    private func initials(for name: String) -> String {
        let words = name.split { !$0.isLetter && !$0.isNumber }.prefix(2)
        let value = words.compactMap(\.first).map(String.init).joined()
        return value.isEmpty ? "TM" : value.uppercased()
    }
}

private struct ProfileToolHeroCard: View {
    let icon: String
    let title: String
    let detail: String
    let status: String
    let statusTint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.tmGreen)
                    .frame(width: 46, height: 46)
                    .background(Color.tmGreen.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(Color.tmInk)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(Color.tmSlate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(status)
                .font(.caption.weight(.bold))
                .foregroundStyle(statusTint)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(statusTint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ProfileToolCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.tmInk)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ProfileToolTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.tmSlate)
            TextField(placeholder, text: $text)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.tmInk)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(Color.tmMist)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct VerificationStepRow: View {
    let icon: String
    let title: String
    let detail: String
    let isComplete: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(isComplete ? Color.tmGreen : Color.tmSlate)
                .frame(width: 34, height: 34)
                .background((isComplete ? Color.tmGreen : Color.tmSlate).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.tmInk)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.tmSlate)
            }

            Spacer()

            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? Color.tmGreen : Color.tmSlate.opacity(0.5))
        }
    }
}

private struct SupportActionRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.tmGreen)
                .frame(width: 36, height: 36)
                .background(Color.tmGreen.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.tmInk)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.tmSlate)
            }
        }
    }
}

private struct ProfileToolNotice: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.tmAmber)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.tmInk)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.tmSlate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.tmAmber.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PassengerSavedTripsToolView: View {
    @EnvironmentObject private var session: AppSession

    private var activeTrips: [PassengerToolTrip] {
        let tripItems = session.passengerTrips
            .filter { [.accepted, .active].contains($0.status) }
            .map(PassengerToolTrip.trip)
        let pendingItems = session.passengerRideRequests
            .filter { $0.status == .pending }
            .map(PassengerToolTrip.request)
        return (tripItems + pendingItems).sorted { $0.sortDate > $1.sortDate }
    }

    var body: some View {
        PassengerToolListView(
            title: "Saved trips",
            icon: "ticket.fill",
            items: activeTrips,
            emptyTitle: "No saved trips yet",
            emptyDetail: "Pending and accepted rides will appear here for quick access.",
            isLoading: session.isPassengerTripsLoading
        )
        .task {
            await session.loadPassengerTrips()
        }
        .refreshable {
            await session.loadPassengerTrips()
        }
    }
}

struct PassengerRideHistoryToolView: View {
    @EnvironmentObject private var session: AppSession

    private var historyItems: [PassengerToolTrip] {
        let tripItems = session.passengerTrips
            .filter { [.completed, .cancelled, .declined].contains($0.status) }
            .map(PassengerToolTrip.trip)
        let requestItems = session.passengerRideRequests
            .filter { [.accepted, .declined, .cancelled, .expired].contains($0.status) }
            .map(PassengerToolTrip.request)
        return (tripItems + requestItems).sorted { $0.sortDate > $1.sortDate }
    }

    var body: some View {
        PassengerToolListView(
            title: "Ride history",
            icon: "clock.arrow.circlepath",
            items: historyItems,
            emptyTitle: "No ride history yet",
            emptyDetail: "Completed, cancelled, and declined rides will appear here.",
            isLoading: session.isPassengerTripsLoading
        )
        .task {
            await session.loadPassengerTrips()
        }
        .refreshable {
            await session.loadPassengerTrips()
        }
    }
}

private struct PassengerToolListView: View {
    let title: String
    let icon: String
    let items: [PassengerToolTrip]
    let emptyTitle: String
    let emptyDetail: String
    let isLoading: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if isLoading && items.isEmpty {
                    ProgressView()
                        .tint(Color.tmGreen)
                        .padding(.top, 42)
                } else if items.isEmpty {
                    PassengerToolEmptyState(icon: icon, title: emptyTitle, detail: emptyDetail)
                        .padding(.top, 24)
                } else {
                    ForEach(items) { item in
                        PassengerToolTripCard(item: item)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.tmMist.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PassengerToolTripCard: View {
    let item: PassengerToolTrip

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .foregroundStyle(item.tint)
                    .frame(width: 40, height: 40)
                    .background(item.tint.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.statusTitle)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.tint)
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(Color.tmInk)
                        .lineLimit(1)
                    Text(item.detail)
                        .font(.subheadline)
                        .foregroundStyle(Color.tmSlate)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Label("\(item.seats) seat\(item.seats == 1 ? "" : "s")", systemImage: "person.2.fill")
                Label(item.priceSummary, systemImage: "dollarsign.circle.fill")
                Spacer()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.tmSlate)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.tmLine, lineWidth: 1)
        }
    }
}

private struct PassengerToolEmptyState: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Color.tmGreen)
                .frame(width: 68, height: 68)
                .background(Color.tmGreen.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.tmInk)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(Color.tmSlate)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PassengerToolTrip: Identifiable {
    let id: String
    let statusTitle: String
    let tint: Color
    let icon: String
    let title: String
    let detail: String
    let seats: Int
    let priceSummary: String
    let sortDate: Date

    static func trip(_ trip: PassengerTrip) -> PassengerToolTrip {
        PassengerToolTrip(
            id: "trip-\(trip.id)",
            statusTitle: trip.status.profileDisplayTitle,
            tint: trip.status.profileTint,
            icon: trip.status.profileIcon,
            title: "\(trip.rideSnapshot.from.displayName) -> \(trip.rideSnapshot.to.displayName)",
            detail: "\(trip.rideSnapshot.departureAt.date.profileDateLabel) with \(trip.rideSnapshot.driverDisplayName)",
            seats: trip.seats,
            priceSummary: CurrencySupport.format(cents: trip.rideSnapshot.pricePerSeatCents, regionCode: trip.rideSnapshot.from.state),
            sortDate: trip.updatedAt.date
        )
    }

    static func request(_ request: JoinRideRequest) -> PassengerToolTrip {
        PassengerToolTrip(
            id: "request-\(request.id)",
            statusTitle: request.status.profileDisplayTitle,
            tint: request.status.profileTint,
            icon: request.status.profileIcon,
            title: "Ride request",
            detail: request.status == .pending ? "Waiting for the driver to respond." : "Request \(request.status.profileDisplayTitle.lowercased()).",
            seats: request.seatsRequested,
            priceSummary: CurrencySupport.format(cents: request.pricePerSeatCents, countryCode: nil),
            sortDate: request.updatedAt.date
        )
    }
}

struct TravelPreferencesView: View {
    @AppStorage("travelPreferenceSeatCount") private var seatCount = 1
    @AppStorage("travelPreferenceLuggage") private var luggageAllowed = true
    @AppStorage("travelPreferencePets") private var petsAllowed = false
    @AppStorage("travelPreferenceSmoking") private var smokingAllowed = false
    @AppStorage("travelPreferenceQuietRide") private var quietRide = false
    @AppStorage("travelPreferencePickupRadius") private var pickupRadius = 10.0

    var body: some View {
        Form {
            Section("Ride defaults") {
                Stepper("Seats: \(seatCount)", value: $seatCount, in: 1...6)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Pickup radius")
                        Spacer()
                        Text("\(Int(pickupRadius)) km")
                            .foregroundStyle(Color.tmSlate)
                    }
                    Slider(value: $pickupRadius, in: 1...50, step: 1)
                        .tint(Color.tmGreen)
                }
            }

            Section("Comfort") {
                Toggle("Luggage allowed", isOn: $luggageAllowed)
                Toggle("Open to pets", isOn: $petsAllowed)
                Toggle("Open to smoking stops", isOn: $smokingAllowed)
                Toggle("Prefer quiet rides", isOn: $quietRide)
            }

            Section {
                Label("These preferences stay on this device for now and will be used as defaults in future passenger flows.", systemImage: "info.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.tmSlate)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.tmMist)
        .navigationTitle("Travel preferences")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color.tmGreen)
    }
}

private extension TripStatus {
    var profileDisplayTitle: String {
        switch self {
        case .pending: "Pending"
        case .accepted: "Accepted"
        case .active: "Active"
        case .completed: "Completed"
        case .declined: "Declined"
        case .cancelled: "Cancelled"
        }
    }

    var profileTint: Color {
        switch self {
        case .pending: Color.tmAmber
        case .accepted, .active: Color.tmGreen
        case .completed: Color.tmInk
        case .declined, .cancelled: Color.tmSlate
        }
    }

    var profileIcon: String {
        switch self {
        case .pending: "hourglass"
        case .accepted, .active: "checkmark.seal.fill"
        case .completed: "flag.checkered"
        case .declined, .cancelled: "xmark.circle.fill"
        }
    }
}

private extension RideRequestStatus {
    var profileDisplayTitle: String {
        switch self {
        case .pending: "Pending"
        case .accepted: "Accepted"
        case .declined: "Declined"
        case .cancelled: "Cancelled"
        case .expired: "Expired"
        }
    }

    var profileTint: Color {
        switch self {
        case .pending: Color.tmAmber
        case .accepted: Color.tmGreen
        case .declined, .cancelled, .expired: Color.tmSlate
        }
    }

    var profileIcon: String {
        switch self {
        case .pending: "hourglass"
        case .accepted: "checkmark.seal.fill"
        case .declined, .cancelled, .expired: "xmark.circle.fill"
        }
    }
}

private extension Date {
    var profileDateLabel: String {
        formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}

private extension String {
    func emptyFallback(_ value: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? value : self
    }
}
