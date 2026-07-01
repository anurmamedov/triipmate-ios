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
    @State private var carMake = ""
    @State private var carModel = ""
    @State private var carYear = ""
    @State private var powerType = "Fuel"
    @State private var bodyType = "Sedan"
    @State private var luggageAllowed = true
    @State private var petsAllowed = false
    @State private var smokingAllowed = false
    @State private var note = ""

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
                    TextField("Car make", text: $carMake)
                    TextField("Car model", text: $carModel)
                    TextField("Car year", text: $carYear)
                        .keyboardType(.numberPad)
                    Picker("Power type", selection: $powerType) {
                        Text("Fuel").tag("Fuel")
                        Text("Electric").tag("Electric")
                        Text("Hybrid").tag("Hybrid")
                    }
                    Picker("Body type", selection: $bodyType) {
                        Text("Sedan").tag("Sedan")
                        Text("Van").tag("Van")
                        Text("SUV").tag("SUV")
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
                RoleSwitchHeader(activeRole: $session.activeRole)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                publishAction
            }
            .scrollContentBackground(.hidden)
            .background(Color.tmMist)
        }
    }

    private var publishAction: some View {
        Button {
        } label: {
            Label("Publish ride", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.tmGreen)
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
}
