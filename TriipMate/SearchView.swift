import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var session: AppSession
    @State private var from = "New York, NY"
    @State private var to = "Chicago, IL"
    @State private var date = Date()
    @State private var seats = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    searchPanel
                    savingsBand
                    rideList
                }
                .padding(20)
            }
            .background(Color.tmMist.ignoresSafeArea())
            .navigationTitle("TriipMate")
            .toolbar { RoleSwitchToolbar(activeRole: $session.activeRole) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Share the road. Split the cost.")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.tmInk)
            Text("Find drivers heading your way and make long-distance travel easier to afford.")
                .font(.subheadline)
                .foregroundStyle(Color.tmSlate)
        }
    }

    private var searchPanel: some View {
        VStack(spacing: 14) {
            RouteField(title: "From", text: $from, icon: "location.fill")
            RouteField(title: "To", text: $to, icon: "mappin.and.ellipse")

            HStack(spacing: 12) {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .padding(12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Stepper(value: $seats, in: 1...6) {
                    Label("\(seats)", systemImage: "person.2.fill")
                        .foregroundStyle(Color.tmInk)
                }
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
            } label: {
                Label("Find rides", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.tmGreen)
        }
        .padding(16)
        .background(Color.tmCloud)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var savingsBand: some View {
        HStack(spacing: 14) {
            Image(systemName: "fuelpump.fill")
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.tmSun)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text("Estimated shared trip cost")
                    .font(.caption)
                    .foregroundStyle(Color.tmSlate)
                Text("$148 per seat instead of about $500 solo")
                    .font(.headline)
                    .foregroundStyle(Color.tmInk)
            }
            Spacer()
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var rideList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended rides")
                .font(.title3.bold())
                .foregroundStyle(Color.tmInk)

            ForEach(SampleData.rides) { ride in
                NavigationLink(value: ride) {
                    RideCard(ride: ride)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: Ride.self) { ride in
            RideDetailView(ride: ride)
        }
    }
}

struct RouteField: View {
    let title: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.tmGreen)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.tmSlate)
                TextField(title, text: $text)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.tmInk)
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
