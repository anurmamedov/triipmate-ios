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

    var body: some View {
        NavigationStack {
            Form {
                Section("Route") {
                    TextField("Leaving from", text: $from)
                    TextField("Going to", text: $to)
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
                                Text("$\(Int(price))")
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
                    if !session.savedVehicles.isEmpty {
                        Picker("Use vehicle", selection: $selectedVehicleID) {
                            ForEach(session.savedVehicles) { vehicle in
                                Text(vehicle.displayName).tag(vehicle.id)
                            }
                            Text("Enter new vehicle").tag("new")
                        }
                    }

                    if let selectedVehicle {
                        HStack(spacing: 12) {
                            Image(systemName: "car.fill")
                                .font(.title3)
                                .foregroundStyle(Color.tmGreen)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(selectedVehicle.displayName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.tmInk)
                                Text("\(selectedVehicle.powerType) · \(selectedVehicle.bodyType)")
                                    .font(.caption)
                                    .foregroundStyle(Color.tmSlate)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        newVehicleFields
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

    @ViewBuilder
    private var newVehicleFields: some View {
        TextField("Car make", text: $carMake)
        TextField("Car model", text: $carModel)
        TextField("Car year", text: $carYear)
            .keyboardType(.numberPad)
            .onChange(of: carYear) { value in
                carYear = String(value.filter { $0.isNumber }.prefix(4))
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
        Toggle("Save this vehicle to my profile", isOn: $saveNewVehicle)
    }

    private func selectDefaultVehicle() {
        guard selectedVehicleID == "new", let firstVehicle = session.savedVehicles.first else { return }
        selectedVehicleID = firstVehicle.id
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
        .accessibilityValue("$\(Int(price))")
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
                    bodyType: bodyType
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
        selectedVehicleID = session.savedVehicles.first?.id ?? "new"
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

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
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
