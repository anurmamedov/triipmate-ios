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

                RideCard(ride: ride)

                detailSection("Trip details") {
                    DetailRow(icon: "car.fill", title: "Vehicle", value: ride.vehicle)
                    DetailRow(icon: "bag.fill", title: "Seats open", value: "\(ride.seats)")
                    DetailRow(icon: "dollarsign.circle.fill", title: "Seat price", value: "$\(ride.price)")
                    DetailRow(icon: "shield.lefthalf.filled", title: "Driver check", value: ride.verified ? "Verified" : "Pending")
                }

                detailSection("Driver note") {
                    Text(ride.notes)
                        .foregroundStyle(Color.tmSlate)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                } label: {
                    Label("Message \(ride.driver)", systemImage: "paperplane.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.tmGreen)

                Button {
                } label: {
                    Label("Request to join this ride", systemImage: "person.badge.plus.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.tmGreen)
            }
            .padding(20)
        }
        .background(Color.tmMist.ignoresSafeArea())
        .navigationTitle("Ride")
        .navigationBarTitleDisplayMode(.inline)
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
