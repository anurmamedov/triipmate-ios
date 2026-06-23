import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: AppSession
    @State private var selectedTab: MainTab = .home

    var body: some View {
        if session.isAuthenticated {
            ZStack {
                if session.activeRole == .passenger {
                    passengerTabs
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity
                        ))
                } else {
                    driverTabs
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity
                        ))
                }
            }
            .tint(.tmGreen)
            .animation(.easeInOut(duration: 0.28), value: session.activeRole)
        } else {
            AuthRootView()
        }
    }

    private var passengerTabs: some View {
        TabView(selection: $selectedTab) {
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(MainTab.home)

            MessagesView()
                .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(MainTab.messages)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(MainTab.profile)
        }
    }

    private var driverTabs: some View {
        TabView(selection: $selectedTab) {
            PublishTripView()
                .tabItem { Label("Post", systemImage: "plus.circle.fill") }
                .tag(MainTab.post)

            DriverDashboardView()
                .tabItem { Label("Requests", systemImage: "person.2.badge.gearshape.fill") }
                .tag(MainTab.home)

            MessagesView()
                .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(MainTab.messages)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(MainTab.profile)
        }
    }
}

private enum MainTab: Hashable {
    case home
    case post
    case messages
    case profile
}

struct RoleSwitchToolbar: ToolbarContent {
    @Binding var activeRole: AppRole

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    activeRole = activeRole == .passenger ? .driver : .passenger
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.tmCloud)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.tmLine, lineWidth: 1)
                        }

                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white)
                        .shadow(color: Color.tmInk.opacity(0.08), radius: 2, y: 1)
                        .frame(width: 42, height: 32)
                        .offset(x: activeRole == .passenger ? -27 : 27)

                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundStyle(activeRole == .passenger ? Color.tmGreen : Color.tmSlate)
                        Spacer()
                        Image(systemName: "car.fill")
                            .foregroundStyle(activeRole == .driver ? Color.tmGreen : Color.tmSlate)
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 13)
                }
                .frame(width: 100, height: 40)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: activeRole)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Switch travel mode")
            .accessibilityValue(activeRole.title)
        }
    }
}

struct DriverDashboardView: View {
    @EnvironmentObject private var session: AppSession
    @State private var requests = SampleData.rideRequests

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    driverHeader
                    actionSummary
                    requestSection
                    driverChecklist
                }
                .padding(20)
            }
            .background(Color.tmMist.ignoresSafeArea())
            .navigationTitle("Driver home")
        }
    }

    private var driverHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("You are driving")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.tmInk)
            Text("Manage your upcoming New York to Chicago trip and choose the passengers you want to ride with.")
                .font(.subheadline)
                .foregroundStyle(Color.tmSlate)
        }
    }

    private var actionSummary: some View {
        HStack(spacing: 12) {
            DriverMetric(value: "\(requests.count)", label: "New requests", icon: "person.badge.clock.fill", color: .tmAmber)
            DriverMetric(value: "2", label: "Open seats", icon: "car.side.fill", color: .tmGreen)
        }
    }

    private var requestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Passenger requests")
                    .font(.title3.bold())
                    .foregroundStyle(Color.tmInk)
                Spacer()
                Text("Review all")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.tmGreen)
            }

            if requests.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.title)
                        .foregroundStyle(Color.tmGreen)
                    Text("All caught up")
                        .font(.headline)
                        .foregroundStyle(Color.tmInk)
                    Text("New passenger requests will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(Color.tmSlate)
                }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(requests) { request in
                    DriverRequestCard(request: request) {
                        requests.removeAll { $0.id == request.id }
                    } onDecline: {
                        requests.removeAll { $0.id == request.id }
                    }
                }
            }
        }
    }

    private var driverChecklist: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Before accepting riders")
                .font(.title3.bold())
                .foregroundStyle(Color.tmInk)
            DriverChecklistRow(icon: "person.text.rectangle.fill", title: "Verify your identity", detail: "Build trust before your first trip", status: "Recommended")
            DriverChecklistRow(icon: "car.fill", title: "Add vehicle details", detail: "Help passengers know what to expect", status: "Required")
            DriverChecklistRow(icon: "creditcard.fill", title: "Set up payouts", detail: "Receive earnings after each ride", status: "Required")
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DriverMetric: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.title3.bold()).foregroundStyle(Color.tmInk)
                Text(label).font(.caption).foregroundStyle(Color.tmSlate)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DriverRequestCard: View {
    let request: RideRequest
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Avatar(initials: request.initials)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(request.passenger).font(.headline).foregroundStyle(Color.tmInk)
                        if request.verified {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.tmGreen)
                        }
                    }
                    Text("\(request.seats) seat\(request.seats == 1 ? "" : "s") • \(request.requestedAt)")
                        .font(.caption).foregroundStyle(Color.tmSlate)
                }
                Spacer()
            }
            Label(request.route, systemImage: "arrow.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tmGreen)
            Text(request.note)
                .font(.subheadline)
                .foregroundStyle(Color.tmSlate)
            HStack(spacing: 10) {
                Button("Decline", action: onDecline)
                    .buttonStyle(.bordered)
                    .tint(Color.tmSlate)
                Button("Accept", action: onAccept)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.tmGreen)
                Spacer()
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DriverChecklistRow: View {
    let icon: String
    let title: String
    let detail: String
    let status: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.tmGreen)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.tmInk)
                Text(detail).font(.caption).foregroundStyle(Color.tmSlate)
            }
            Spacer()
            Text(status)
                .font(.caption.weight(.semibold))
                .foregroundStyle(status == "Required" ? Color.tmAmber : Color.tmSlate)
        }
    }
}
