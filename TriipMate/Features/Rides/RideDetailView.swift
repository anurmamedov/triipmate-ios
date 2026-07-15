import SwiftUI

struct RideDetailView: View {
    @EnvironmentObject private var session: AppSession
    let ride: Ride
    @State private var isRequestSheetPresented = false
    @State private var isSafetyReportPresented = false
    @State private var isResultAlertPresented = false
    @State private var requestResultMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(ride.from) → \(ride.to)")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color.tmInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .allowsTightening(true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(ride.date) at \(ride.time)")
                        .foregroundStyle(Color.tmSlate)
                }

                topSummary

                detailSection("Trip details") {
                    DetailRow(icon: "clock.fill", title: "Start time", value: ride.time)
                    DetailRow(icon: "clock.badge.checkmark.fill", title: "Expected end time", value: ride.endTime)
                    RouteDetailBlock(from: ride.from, to: ride.to)
                    DetailRow(icon: "timer", title: "Trip time", value: ride.tripTime)
                    DetailRow(icon: "person.2.fill", title: "Current available seats", value: "\(ride.seats)")
                    DetailRow(icon: "carseat.left.fill", title: "Total seats", value: "\(ride.totalSeats)")
                }

                detailSection("Vehicle details") {
                    DetailRow(icon: "car.fill", title: "Car make", value: ride.carMake)
                    DetailRow(icon: "car.side.fill", title: "Car model", value: ride.carModel)
                    DetailRow(icon: "calendar", title: "Car year", value: ride.carYear)
                    DetailRow(icon: "fuelpump.fill", title: "Fuel/Electric/Hybrid", value: ride.powerType)
                    DetailRow(icon: "rectangle.3.group.bubble.left.fill", title: "Sedan/Van", value: ride.bodyType)
                }

                detailSection("Driver note") {
                    Text(ride.notes)
                        .foregroundStyle(Color.tmSlate)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                detailSection("Safety") {
                    DetailRow(icon: "checkmark.seal.fill", title: "Driver check", value: ride.verified ? "Verified" : "Pending")
                    DetailRow(icon: "star.fill", title: "Driver rating", value: String(format: "%.1f", ride.rating))
                    DetailRow(icon: "bubble.left.and.bubble.right.fill", title: "Trip chat", value: "Available after request")
                }

                Button {
                    isRequestSheetPresented = true
                } label: {
                    Label("Request to join this ride", systemImage: "person.badge.plus.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.tmGreen)
                .disabled(ride.seats <= 0 || session.isRideRequestWorking)

                Button {
                    isSafetyReportPresented = true
                } label: {
                    Label("Report safety concern", systemImage: "shield.lefthalf.filled")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .tint(Color.tmAmber)

                Button {
                } label: {
                    Label("Message \(ride.driver)", systemImage: "paperplane.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .tint(Color.tmGreen)
            }
            .padding(20)
        }
        .background(Color.tmMist.ignoresSafeArea())
        .navigationTitle("Ride")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isRequestSheetPresented) {
            RideRequestFormView(ride: ride) { message in
                requestResultMessage = message
                isResultAlertPresented = true
            }
            .environmentObject(session)
        }
        .sheet(isPresented: $isSafetyReportPresented) {
            SafetyReportSheet(ride: ride) { message in
                requestResultMessage = message
                isResultAlertPresented = true
            }
            .environmentObject(session)
        }
        .alert(requestResultMessage, isPresented: $isResultAlertPresented) {
            Button("OK", role: .cancel) { }
        }
    }

    private var topSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Avatar(initials: ride.initials)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(ride.driver)
                            .font(.headline)
                            .foregroundStyle(Color.tmInk)
                        if ride.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.tmGreen)
                        }
                    }
                    Label(String(format: "%.1f rating", ride.rating), systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Color.tmAmber)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(ride.priceSummary)
                        .font(.title2.bold())
                        .foregroundStyle(Color.tmInk)
                    Text("per seat")
                        .font(.caption)
                        .foregroundStyle(Color.tmSlate)
                }
            }

            HStack {
                Label("\(ride.seats) seats left", systemImage: "person.2.fill")
                Spacer()
                Label(ride.vehicle, systemImage: "car.fill")
            }
            .font(.caption)
            .foregroundStyle(Color.tmSlate)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.tmLine, lineWidth: 1)
        )
    }

    private func detailSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.tmInk)
            content()
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SafetyReportSheet: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    let ride: Ride
    let onComplete: (String) -> Void
    @State private var category = "Unsafe behavior"
    @State private var details = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Safety report", systemImage: "shield.lefthalf.filled")
                            .font(.title3.bold())
                            .foregroundStyle(Color.tmInk)
                        Text("\(ride.from) → \(ride.to)")
                            .font(.subheadline)
                            .foregroundStyle(Color.tmSlate)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 14) {
                        Picker("Reason", selection: $category) {
                            Text("Unsafe behavior").tag("Unsafe behavior")
                            Text("Suspicious profile").tag("Suspicious profile")
                            Text("Wrong ride details").tag("Wrong ride details")
                            Text("Payment concern").tag("Payment concern")
                        }
                        .pickerStyle(.menu)

                        TextField("Describe what happened", text: $details, axis: .vertical)
                            .lineLimit(5...8)
                            .padding(12)
                            .background(Color.tmMist)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text("Reports are saved for review. For immediate danger, contact local emergency services first.")
                            .font(.caption)
                            .foregroundStyle(Color.tmSlate)
                    }
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    if let error = session.authError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.tmAmber)
                            .padding(12)
                            .background(Color.tmAmber.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(20)
            }
            .background(Color.tmMist.ignoresSafeArea())
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(session.isAccountToolsWorking ? "Sending" : "Send") {
                        Task {
                            let didSend = await session.submitSafetyReport(ride: ride, category: category, details: details)
                            if didSend {
                                dismiss()
                                onComplete("Safety report sent for review.")
                            }
                        }
                    }
                    .disabled(session.isAccountToolsWorking || details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .tint(Color.tmGreen)
        }
    }
}

struct RideRequestFormView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    let ride: Ride
    let onComplete: (String) -> Void
    @State private var seatsRequested = 1
    @State private var pickupNote = ""
    @State private var dropoffNote = ""
    @State private var luggageNote = ""
    @State private var message = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Ride") {
                    LabeledContent("Route", value: "\(ride.from) to \(ride.to)")
                    LabeledContent("Departure", value: "\(ride.date) at \(ride.time)")
                    LabeledContent("Seat price", value: ride.priceSummary)
                }

                Section("Request") {
                    Stepper(value: $seatsRequested, in: 1...max(ride.seats, 1)) {
                        Text("\(seatsRequested) seat\(seatsRequested == 1 ? "" : "s")")
                    }
                    TextField("Pickup note", text: $pickupNote)
                    TextField("Drop-off note", text: $dropoffNote)
                    TextField("Luggage note", text: $luggageNote)
                    TextField("Message to driver", text: $message, axis: .vertical)
                        .lineLimit(3...5)
                }

                if let error = session.authError {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .navigationTitle("Join request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(session.isRideRequestWorking ? "Sending" : "Send") {
                        Task {
                            let didSend = await session.submitRideRequest(
                                for: ride,
                                seatsRequested: seatsRequested,
                                pickupNote: pickupNote,
                                dropoffNote: dropoffNote,
                                luggageNote: luggageNote,
                                message: message
                            )
                            if didSend {
                                dismiss()
                                onComplete("Request sent to \(ride.driver).")
                            }
                        }
                    }
                    .disabled(session.isRideRequestWorking || ride.seats <= 0)
                }
            }
            .onAppear {
                seatsRequested = min(seatsRequested, max(ride.seats, 1))
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Label(title, systemImage: icon)
                .foregroundStyle(Color.tmSlate)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(Color.tmInk)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .multilineTextAlignment(.trailing)
                .layoutPriority(1)
        }
    }
}

struct RouteDetailBlock: View {
    let from: String
    let to: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Route", systemImage: "point.topleft.down.curvedto.point.bottomright.up.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tmSlate)

            HStack(spacing: 10) {
                Text(from)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.tmGreen)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.white))
                Text(to)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.tmInk)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .allowsTightening(true)
        }
        .padding(12)
        .background(Color.tmGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Route \(from) to \(to)")
    }
}
