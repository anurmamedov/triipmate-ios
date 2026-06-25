import SwiftUI

struct RideDetailView: View {
    let ride: Ride

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(ride.from) to \(ride.to)")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color.tmInk)
                    Text("\(ride.date) at \(ride.time)")
                        .foregroundStyle(Color.tmSlate)
                }

                topSummary

                detailSection("Trip details") {
                    DetailRow(icon: "clock.fill", title: "Start time", value: ride.time)
                    DetailRow(icon: "clock.badge.checkmark.fill", title: "Expected end time", value: ride.endTime)
                    DetailRow(icon: "point.topleft.down.curvedto.point.bottomright.up.fill", title: "Route", value: "\(ride.from) / \(ride.to)")
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
                } label: {
                    Label("Request to join this ride", systemImage: "person.badge.plus.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.tmGreen)

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
                    Text("$\(ride.price)")
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

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(Color.tmSlate)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(Color.tmInk)
        }
    }
}
