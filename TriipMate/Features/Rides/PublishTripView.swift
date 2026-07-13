import SwiftUI

struct PublishTripView: View {
    @EnvironmentObject private var session: AppSession
    @State private var from = ""
    @State private var to = ""
    @State private var pickupPoint = ""
    @State private var dropoffPoint = ""
    @State private var date = Date()
    @State private var startTime = Date()
    @State private var arrivalTime = Date()
    @State private var totalSeats = 4
    @State private var seats = 2
    @State private var price = 120.0
    @State private var selectedVehicleID = "new"
    @State private var carMake = ""
    @State private var carModel = ""
    @State private var carYear = ""
    @State private var powerType = "Fuel"
    @State private var bodyType = "Sedan"
    @State private var saveNewVehicle = false
    @State private var luggageAllowed = true
    @State private var petsAllowed = false
    @State private var smokingAllowed = false
    @State private var note = ""
    @State private var publishMessage: PublishMessage?
    @State private var isVehicleSheetPresented = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Route") {
                    PostRideRouteAutocompleteField(title: "Leaving from", text: $from, icon: "location.fill")
                    PostRideRouteAutocompleteField(title: "Going to", text: $to, icon: "mappin.and.ellipse")
                    TextField("Pickup point", text: $pickupPoint)
                    TextField("Drop-off point", text: $dropoffPoint)
                }

                Section("Schedule") {
                    DatePicker("Departure date", selection: $date, displayedComponents: .date)
                    DatePicker("Start time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("Expected arrival", selection: $arrivalTime, displayedComponents: .hourAndMinute)
                }

                Section("Seats and price") {
                    Stepper("Total seats: \(totalSeats)", value: $totalSeats, in: 1...8)
                    Stepper("Available seats: \(seats)", value: $seats, in: 1...totalSeats)
                    VStack(spacing: 14) {
                        priceSlider

                        HStack(spacing: 16) {
                            priceButton(systemImage: "minus", accessibilityLabel: "Decrease price") {
                                price = max(25, price - 1)
                            }
                            .disabled(price <= 25)

                            VStack(spacing: 2) {
                                Text(CurrencySupport.format(dollars: price, currencyCode: CurrencySupport.code(forRegionCode: from.routeRegionCode)))
                                    .font(.title2.bold())
                                    .foregroundStyle(Color.tmInk)
                                Text("per seat")
                                    .font(.caption)
                                    .foregroundStyle(Color.tmSlate)
                            }
                            .frame(maxWidth: .infinity)

                            priceButton(systemImage: "plus", accessibilityLabel: "Increase price") {
                                price = min(1500, price + 1)
                            }
                            .disabled(price >= 1500)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowSeparator(.hidden)
                }

                Section("Vehicle") {
                    Button {
                        isVehicleSheetPresented = true
                    } label: {
                        VehicleSummaryCard(
                            selectedVehicle: selectedVehicle,
                            carMake: carMake,
                            carModel: carModel,
                            carYear: carYear,
                            powerType: powerType,
                            bodyType: bodyType
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .textCase(nil)

                if selectedVehicle == nil && (!carMake.trimmed.isEmpty || !carModel.trimmed.isEmpty || !carYear.trimmed.isEmpty) {
                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: saveNewVehicle ? "checkmark.seal.fill" : "info.circle.fill")
                                .foregroundStyle(saveNewVehicle ? Color.tmGreen : Color.tmSlate)
                            Text(saveNewVehicle ? "This new vehicle will be saved to your profile." : "This new vehicle will be used only for this ride.")
                                .font(.footnote)
                                .foregroundStyle(Color.tmSlate)
                        }
                    }
                }

                Section("Rules") {
                    Toggle("Luggage allowed", isOn: $luggageAllowed)
                    Toggle("Pets allowed", isOn: $petsAllowed)
                    Toggle("Smoking allowed", isOn: $smokingAllowed)
                }

                Section("Trip note") {
                    TextField("Pickup details, luggage space, stops", text: $note, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                RoleSwitchHeader()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                publishAction
            }
            .scrollContentBackground(.hidden)
            .background(Color.tmMist)
            .onAppear(perform: selectDefaultVehicle)
            .sheet(isPresented: $isVehicleSheetPresented) {
                VehicleSelectionSheet(
                    selectedVehicleID: $selectedVehicleID,
                    carMake: $carMake,
                    carModel: $carModel,
                    carYear: $carYear,
                    powerType: $powerType,
                    bodyType: $bodyType,
                    saveNewVehicle: $saveNewVehicle
                )
                .environmentObject(session)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .alert(item: $publishMessage) { message in
                Alert(
                    title: Text(message.title),
                    message: Text(message.body),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var selectedVehicle: SavedVehicle? {
        session.savedVehicles.first { $0.id == selectedVehicleID }
    }

    private func selectDefaultVehicle() {
        guard selectedVehicleID == "new" else { return }
        selectedVehicleID = session.savedVehicles.first(where: \.isDefault)?.id ?? session.savedVehicles.first?.id ?? "new"
    }

    private var publishAction: some View {
        Button {
            Task {
                await publishRide()
            }
        } label: {
            if session.isRidePublishing {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            } else {
                Label("Publish ride", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.tmGreen)
        .disabled(session.isRidePublishing)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.tmMist)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.tmLine)
                .frame(height: 1)
        }
    }

    private var priceSlider: some View {
        GeometryReader { geometry in
            let thumbSize = 28.0
            let availableWidth = max(geometry.size.width - thumbSize, 1)
            let progress = (price - 25) / (1500 - 25)
            let thumbOffset = availableWidth * progress

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.tmLine)
                    .frame(height: 4)
                    .padding(.horizontal, thumbSize / 2)

                Capsule()
                    .fill(Color.tmGreen)
                    .frame(width: max(thumbOffset, 0), height: 4)
                    .offset(x: thumbSize / 2)

                Circle()
                    .fill(.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: Color.black.opacity(0.12), radius: 4, y: 1)
                    .offset(x: thumbOffset)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let location = min(max(gesture.location.x - thumbSize / 2, 0), availableWidth)
                        price = (25 + (location / availableWidth) * (1500 - 25)).rounded()
                    }
            )
        }
        .frame(height: 32)
        .accessibilityElement()
        .accessibilityLabel("Price per seat")
        .accessibilityValue(CurrencySupport.format(dollars: price, currencyCode: CurrencySupport.code(forRegionCode: from.routeRegionCode)))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                price = min(1500, price + 1)
            case .decrement:
                price = max(25, price - 1)
            @unknown default:
                break
            }
        }
    }

    private func priceButton(
        systemImage: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                action()
            }
        } label: {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.tmGreen)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    @MainActor
    private func publishRide() async {
        guard let profile = session.userProfile else {
            publishMessage = .failure("Please log in before publishing a ride.")
            return
        }

        let trimmedFrom = from.trimmed
        let trimmedTo = to.trimmed
        let trimmedMake = carMake.trimmed
        let trimmedModel = carModel.trimmed
        let trimmedYear = carYear.trimmed

        guard !trimmedFrom.isEmpty, !trimmedTo.isEmpty else {
            publishMessage = .failure("Please add both route cities.")
            return
        }

        guard seats <= totalSeats else {
            publishMessage = .failure("Available seats cannot be more than total seats.")
            return
        }

        let vehicleSnapshot: VehicleSnapshot
        var vehicleToSave: SavedVehicle?

        if let selectedVehicle {
            vehicleSnapshot = VehicleSnapshot(
                vehicleId: selectedVehicle.id,
                make: selectedVehicle.make,
                model: selectedVehicle.model,
                year: selectedVehicle.year,
                powerType: selectedVehicle.powerType,
                bodyType: selectedVehicle.bodyType
            )
        } else {
            guard !trimmedMake.isEmpty, !trimmedModel.isEmpty, trimmedYear.count == 4 else {
                publishMessage = .failure("Please complete the vehicle details.")
                return
            }

            let vehicleId = UUID().uuidString.lowercased()
            vehicleSnapshot = VehicleSnapshot(
                vehicleId: saveNewVehicle ? vehicleId : nil,
                make: trimmedMake,
                model: trimmedModel,
                year: trimmedYear,
                powerType: powerType,
                bodyType: bodyType
            )

            if saveNewVehicle {
                vehicleToSave = SavedVehicle(
                    id: vehicleId,
                    make: trimmedMake,
                    model: trimmedModel,
                    year: trimmedYear,
                    powerType: powerType,
                    bodyType: bodyType,
                    isDefault: session.savedVehicles.isEmpty
                )
            }
        }

        let departureDate = combinedDate(day: date, time: startTime)
        var arrivalDate = combinedDate(day: date, time: arrivalTime)
        if arrivalDate <= departureDate {
            arrivalDate = Calendar.current.date(byAdding: .day, value: 1, to: arrivalDate) ?? arrivalDate
        }

        let now = Date()
        let ride = MarketplaceRide(
            id: UUID().uuidString.lowercased(),
            driverUid: profile.uid,
            driverDisplayName: profile.displayName,
            driverProfilePhotoPath: profile.profilePhotoPath,
            from: RouteEndpoint(displayName: trimmedFrom),
            to: RouteEndpoint(displayName: trimmedTo),
            departureAt: FirestoreTimestamp(date: departureDate),
            expectedArrivalAt: FirestoreTimestamp(date: arrivalDate),
            estimatedDurationMinutes: max(Int(arrivalDate.timeIntervalSince(departureDate) / 60), 1),
            availableSeats: seats,
            totalSeats: totalSeats,
            pricePerSeatCents: Int(price.rounded()) * 100,
            vehicle: vehicleSnapshot,
            status: .published,
            notes: publishNotes,
            createdAt: FirestoreTimestamp(date: now),
            updatedAt: FirestoreTimestamp(date: now)
        )

        if await session.publishRide(ride, vehicleToSave: vehicleToSave) {
            resetFormAfterPublish()
            publishMessage = .success("Your ride was saved to Firestore and is ready for passenger search in the next step.")
        } else {
            publishMessage = .failure(session.authError ?? "The ride could not be published.")
        }
    }

    private var publishNotes: String {
        var lines: [String] = []

        if !pickupPoint.trimmed.isEmpty {
            lines.append("Pickup: \(pickupPoint.trimmed)")
        }

        if !dropoffPoint.trimmed.isEmpty {
            lines.append("Drop-off: \(dropoffPoint.trimmed)")
        }

        lines.append("Luggage: \(luggageAllowed ? "Allowed" : "Not allowed")")
        lines.append("Pets: \(petsAllowed ? "Allowed" : "Not allowed")")
        lines.append("Smoking: \(smokingAllowed ? "Allowed" : "Not allowed")")

        if !note.trimmed.isEmpty {
            lines.append(note.trimmed)
        }

        return lines.joined(separator: "\n")
    }

    private func combinedDate(day: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var components = DateComponents()
        components.year = dayComponents.year
        components.month = dayComponents.month
        components.day = dayComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        return calendar.date(from: components) ?? day
    }

    private func resetFormAfterPublish() {
        from = ""
        to = ""
        pickupPoint = ""
        dropoffPoint = ""
        date = Date()
        startTime = Date()
        arrivalTime = Date()
        totalSeats = 4
        seats = 2
        price = 120
        selectedVehicleID = session.savedVehicles.first(where: \.isDefault)?.id ?? session.savedVehicles.first?.id ?? "new"
        carMake = ""
        carModel = ""
        carYear = ""
        powerType = "Fuel"
        bodyType = "Sedan"
        saveNewVehicle = false
        luggageAllowed = true
        petsAllowed = false
        smokingAllowed = false
        note = ""
    }
}

private struct PublishMessage: Identifiable {
    let id = UUID()
    let title: String
    let body: String

    static func success(_ body: String) -> PublishMessage {
        PublishMessage(title: "Ride published", body: body)
    }

    static func failure(_ body: String) -> PublishMessage {
        PublishMessage(title: "Cannot publish ride", body: body)
    }
}

private struct VehicleSummaryCard: View {
    let selectedVehicle: SavedVehicle?
    let carMake: String
    let carModel: String
    let carYear: String
    let powerType: String
    let bodyType: String

    private var hasNewVehicleDetails: Bool {
        !carMake.trimmed.isEmpty || !carModel.trimmed.isEmpty || !carYear.trimmed.isEmpty
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "car.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.tmGreen)
                .frame(width: 44, height: 44)
                .background(Color.tmGreen.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.tmInk)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.tmSlate)
            }

            Spacer()

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.tmSlate)
                .frame(width: 28, height: 28)
                .background(Color.tmCloud)
                .clipShape(Circle())
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.tmLine.opacity(0.9), lineWidth: 1)
        }
    }

    private var title: String {
        if let selectedVehicle {
            return selectedVehicle.displayName
        }
        if hasNewVehicleDetails {
            return [carYear.trimmed, carMake.trimmed, carModel.trimmed]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
        return "Choose vehicle"
    }

    private var subtitle: String {
        if let selectedVehicle {
            return selectedVehicle.isDefault ? "\(selectedVehicle.powerType) · \(selectedVehicle.bodyType) · Default" : "\(selectedVehicle.powerType) · \(selectedVehicle.bodyType)"
        }
        if hasNewVehicleDetails {
            return "\(powerType) · \(bodyType) · New vehicle"
        }
        return "Select a saved car or add one for this ride"
    }
}

private struct VehicleSelectionSheet: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedVehicleID: String
    @Binding var carMake: String
    @Binding var carModel: String
    @Binding var carYear: String
    @Binding var powerType: String
    @Binding var bodyType: String
    @Binding var saveNewVehicle: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !session.savedVehicles.isEmpty {
                        savedVehicleSection
                    }

                    newVehicleSection
                }
                .padding(20)
            }
            .background(Color.tmMist.ignoresSafeArea())
            .navigationTitle("Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.tmGreen)
                }
            }
        }
    }

    private var savedVehicleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved vehicles")
                .font(.headline)
                .foregroundStyle(Color.tmInk)

            VStack(spacing: 10) {
                ForEach(session.savedVehicles) { vehicle in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            selectedVehicleID = vehicle.id
                        }
                        dismiss()
                    } label: {
                        VehicleSheetCard(vehicle: vehicle, isSelected: selectedVehicleID == vehicle.id)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var newVehicleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Add a new vehicle")
                    .font(.headline)
                    .foregroundStyle(Color.tmInk)
                Spacer()
                if selectedVehicleID == "new" {
                    Label("Selected", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.tmGreen)
                }
            }

            VStack(spacing: 12) {
                VehicleInputRow(title: "Make", placeholder: "Toyota", text: $carMake)
                VehicleInputRow(title: "Model", placeholder: "Corolla", text: $carModel)
                VehicleInputRow(title: "Year", placeholder: "2022", text: $carYear, keyboardType: .numberPad)
                    .onChange(of: carYear) { value in
                        carYear = String(value.filter { $0.isNumber }.prefix(4))
                    }

                HStack(spacing: 10) {
                    MenuPickerPill(title: "Power", selection: $powerType, options: ["Fuel", "Electric", "Hybrid"], icon: "fuelpump.fill")
                    MenuPickerPill(title: "Body", selection: $bodyType, options: ["Sedan", "SUV", "Van", "Truck", "Hatchback"], icon: "rectangle.3.group.fill")
                }

                Toggle(isOn: $saveNewVehicle) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Save to profile")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.tmInk)
                        Text("Use it faster next time")
                            .font(.caption)
                            .foregroundStyle(Color.tmSlate)
                    }
                }
                .toggleStyle(.switch)
                .tint(Color.tmGreen)
                .padding(12)
                .background(Color.tmCloud.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        selectedVehicleID = "new"
                    }
                    dismiss()
                } label: {
                    Label("Use this vehicle", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.tmGreen)
            }
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedVehicleID == "new" ? Color.tmGreen.opacity(0.45) : Color.tmLine, lineWidth: 1)
            }
        }
    }
}

private struct VehicleSheetCard: View {
    let vehicle: SavedVehicle
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.headline)
                .foregroundStyle(isSelected ? .white : Color.tmGreen)
                .frame(width: 38, height: 38)
                .background(isSelected ? Color.tmGreen : Color.tmGreen.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(vehicle.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.tmInk)
                    if vehicle.isDefault {
                        Text("Default")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.tmGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.tmGreen.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                Text("\(vehicle.powerType) · \(vehicle.bodyType)")
                    .font(.caption)
                    .foregroundStyle(Color.tmSlate)
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Color.tmGreen : Color.tmLine)
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.tmGreen.opacity(0.5) : Color.tmLine, lineWidth: 1)
        }
    }
}

private struct VehicleInputRow: View {
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

private struct PostRideRouteAutocompleteField: View {
    let title: String
    @Binding var text: String
    let icon: String
    @FocusState private var isFocused: Bool

    private var suggestions: [NorthAmericaLocation] {
        NorthAmericaLocation.suggestions(matching: text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.tmGreen)
                    .frame(width: 22)

                TextField(title, text: $text)
                    .font(.body)
                    .foregroundStyle(Color.tmInk)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            }

            if isFocused && !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(suggestions) { location in
                        Button {
                            text = location.displayName
                            isFocused = false
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(Color.tmGreen)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(location.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.tmInk)
                                    Text("\(location.regionName), \(location.country)")
                                        .font(.caption)
                                        .foregroundStyle(Color.tmSlate)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        if location.id != suggestions.last?.id {
                            Divider()
                                .padding(.leading, 30)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
    }
}

private struct MenuPickerPill: View {
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

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var routeRegionCode: String {
        split(separator: ",")
            .last
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) } ?? ""
    }
}

private extension UserProfile {
    var displayName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension RouteEndpoint {
    init(displayName: String) {
        let parts = displayName
            .split(separator: ",", maxSplits: 1)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        let city = parts.first ?? displayName
        let state = parts.count > 1 ? parts[1] : ""
        self.init(
            city: city,
            state: state,
            displayName: displayName,
            normalizedName: displayName
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
