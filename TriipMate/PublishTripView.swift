import SwiftUI

struct PublishTripView: View {
    @EnvironmentObject private var session: AppSession
    @State private var from = ""
    @State private var to = ""
    @State private var date = Date()
    @State private var seats = 2
    @State private var price = 120.0
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Route") {
                    TextField("Leaving from", text: $from)
                    TextField("Going to", text: $to)
                    DatePicker("Departure", selection: $date)
                }

                Section("Seats and price") {
                    Stepper("Open seats: \(seats)", value: $seats, in: 1...7)
                    Slider(value: $price, in: 25...300, step: 5) {
                        Text("Price")
                    }
                    Text("$\(Int(price)) per seat")
                        .font(.headline)
                        .foregroundStyle(Color.tmGreen)
                }

                Section("Trip note") {
                    TextField("Pickup details, luggage space, stops", text: $note, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }

                Button {
                } label: {
                    Label("Publish ride", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Post a ride")
            .toolbar { RoleSwitchToolbar(activeRole: $session.activeRole) }
            .scrollContentBackground(.hidden)
            .background(Color.tmMist)
        }
    }
}
