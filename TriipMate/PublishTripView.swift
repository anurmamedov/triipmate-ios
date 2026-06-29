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
                    Slider(value: $price, in: 25...300, step: 5) {
                        Text("Price")
                    }
                    Text("$\(Int(price)) per seat")
                        .font(.headline)
                        .foregroundStyle(Color.tmGreen)
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
}
