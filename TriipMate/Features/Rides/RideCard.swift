import SwiftUI

struct RideCard: View {
    let ride: Ride

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(ride.from, systemImage: "location.fill")
                    Label(ride.to, systemImage: "mappin.and.ellipse")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tmInk)

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
                Label("\(ride.date), \(ride.time)", systemImage: "calendar")
                Spacer()
                Label("\(ride.seats) seats left", systemImage: "person.2.fill")
            }
            .font(.caption)
            .foregroundStyle(Color.tmSlate)

            HStack {
                Avatar(initials: ride.initials)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(ride.driver)
                            .font(.headline)
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
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.tmLine, lineWidth: 1)
        )
    }
}

struct Avatar: View {
    let initials: String

    var body: some View {
        Text(initials)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(Color.tmGreen)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
