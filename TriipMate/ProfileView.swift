import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Avatar(initials: "AA")
                            .scaleEffect(1.25)
                            .padding(.bottom, 8)
                        Text("Aymammet")
                            .font(.title2.bold())
                            .foregroundStyle(Color.tmInk)
                        Label(
                            session.activeRole == .driver ? "Verified driver" : "Verified traveler",
                            systemImage: "checkmark.seal.fill"
                        )
                            .foregroundStyle(Color.tmGreen)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    HStack(spacing: 12) {
                        StatTile(value: "4.9", label: "Rating")
                        StatTile(value: "18", label: "Trips")
                        StatTile(value: "$1.2k", label: "Saved")
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        SettingsRow(icon: "person.text.rectangle.fill", title: "Identity and license")
                        SettingsRow(icon: "creditcard.fill", title: "Payment methods")
                        SettingsRow(icon: "bell.fill", title: "Trip alerts")
                        SettingsRow(icon: "questionmark.circle.fill", title: "Support")
                        Button {
                            session.logout()
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
                            SettingsRow(icon: "car.fill", title: "Vehicle details")
                            SettingsRow(icon: "person.2.badge.gearshape.fill", title: "Passenger requests")
                            SettingsRow(icon: "dollarsign.circle.fill", title: "Payout setup")
                        } else {
                            SettingsRow(icon: "ticket.fill", title: "Saved trips")
                            SettingsRow(icon: "clock.arrow.circlepath", title: "Ride history")
                            SettingsRow(icon: "slider.horizontal.3", title: "Travel preferences")
                        }
                    }
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(20)
            }
            .background(Color.tmMist.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) {
                RoleSwitchHeader(activeRole: $session.activeRole)
            }
        }
    }
}

struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.tmInk)
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
