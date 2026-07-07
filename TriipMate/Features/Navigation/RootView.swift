import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: AppSession
    @State private var selectedTab: MainTab = .home

    var body: some View {
        if session.isRestoringSession {
            VStack(spacing: 16) {
                Image(systemName: "car.2.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.tmGreen)
                ProgressView("Restoring your session...")
                    .tint(Color.tmGreen)
                    .foregroundStyle(Color.tmSlate)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.tmMist.ignoresSafeArea())
        } else if session.isAuthenticated {
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
            .onChange(of: session.activeRole) { _ in
                selectedTab = .home
            }
        } else {
            AuthRootView()
        }
    }

    private var passengerTabs: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .home, .post:
                    SearchView()
                case .trips:
                    PassengerTripsView()
                case .messages:
                    MessagesView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            MainTabBar(role: .passenger, selectedTab: $selectedTab)
        }
    }

    private var driverTabs: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .post:
                    PublishTripView()
                case .home:
                    DriverDashboardView()
                case .trips:
                    PostedTripsView()
                case .messages:
                    MessagesView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            MainTabBar(role: .driver, selectedTab: $selectedTab)
        }
    }
}

private enum MainTab: Hashable {
    case home
    case post
    case trips
    case messages
    case profile
}

private struct MainTabItem: Identifiable {
    let tab: MainTab
    let title: String
    let icon: String

    var id: MainTab { tab }
}

private struct MainTabBar: View {
    let role: AppRole
    @Binding var selectedTab: MainTab
    @Namespace private var selectionAnimation

    private var items: [MainTabItem] {
        if role == .driver {
            return [
                MainTabItem(tab: .post, title: "Post ride", icon: "plus.circle.fill"),
                MainTabItem(tab: .home, title: "Requests", icon: "person.2.badge.gearshape.fill"),
                MainTabItem(tab: .trips, title: "My Trips", icon: "car.2.fill"),
                MainTabItem(tab: .messages, title: "Messages", icon: "bubble.left.and.bubble.right.fill"),
                MainTabItem(tab: .profile, title: "Profile", icon: "person.crop.circle.fill")
            ]
        }

        return [
            MainTabItem(tab: .home, title: "Search", icon: "magnifyingglass"),
            MainTabItem(tab: .trips, title: "My Trips", icon: "ticket.fill"),
            MainTabItem(tab: .messages, title: "Messages", icon: "bubble.left.and.bubble.right.fill"),
            MainTabItem(tab: .profile, title: "Profile", icon: "person.crop.circle.fill")
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: role == .driver ? 2 : 5) {
                ForEach(items) { item in
                    Button {
                        selectedTab = item.tab
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: item.icon)
                                .font(.system(size: 19, weight: .semibold))
                                .frame(height: 22)
                                .foregroundStyle(selectedTab == item.tab ? Color.tmGreen : Color.white.opacity(0.62))
                            Text(item.title)
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                                .foregroundStyle(selectedTab == item.tab ? Color.white : Color.white.opacity(0.62))
                        }
                        .frame(width: role == .driver ? 65 : 72, height: 50)
                        .background {
                            if selectedTab == item.tab {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.12))
                                    .matchedGeometryEffect(id: "selected-tab", in: selectionAnimation)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.title)
                    .accessibilityAddTraits(selectedTab == item.tab ? .isSelected : [])
                }
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.88), value: selectedTab)
            .padding(6)
            .background(Color(red: 0.04, green: 0.15, blue: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.tmInk.opacity(0.18), radius: 12, y: 5)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .background(Color.tmMist.ignoresSafeArea(edges: .bottom))
    }
}

struct RoleSwitchHeader: View {
    @Binding var activeRole: AppRole

    var body: some View {
        HStack {
            Spacer()
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    activeRole = activeRole == .passenger ? .driver : .passenger
                }
            } label: {
                ZStack(alignment: activeRole == .passenger ? .leading : .trailing) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.tmCloud)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.tmLine, lineWidth: 1)
                        }

                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white)
                        .shadow(color: Color.tmInk.opacity(0.08), radius: 2, y: 1)
                        .frame(width: 40, height: 30)
                        .padding(3)

                    HStack(spacing: 0) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(activeRole == .passenger ? Color.tmGreen : Color.tmSlate)
                            .frame(width: 44, height: 36)
                        Image(systemName: "car.fill")
                            .foregroundStyle(activeRole == .driver ? Color.tmGreen : Color.tmSlate)
                            .frame(width: 44, height: 36)
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .frame(width: 88, height: 36)
                .animation(.spring(response: 0.38, dampingFraction: 0.86), value: activeRole)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Switch travel mode")
            .accessibilityValue(activeRole.title)
        }
        .frame(height: 48)
        .padding(.horizontal, 20)
        .background(Color.tmMist)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.tmLine.opacity(0.7))
                .frame(height: 1)
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
            .safeAreaInset(edge: .top, spacing: 0) {
                RoleSwitchHeader(activeRole: $session.activeRole)
            }
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

struct PassengerTripsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Track requested, accepted, and completed rides in one place.")
                        .font(.subheadline)
                        .foregroundStyle(Color.tmSlate)

                    TripStatusCard(status: "Pending request", title: "New York to Chicago", detail: "Waiting for Maya Chen to accept your seat request.", icon: "hourglass")
                    TripStatusCard(status: "Accepted", title: "Philadelphia to Pittsburgh", detail: "Pickup details are confirmed in Messages.", icon: "checkmark.seal.fill")
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

struct PostedTripsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Manage active routes, open seats, and passenger requests.")
                        .font(.subheadline)
                        .foregroundStyle(Color.tmSlate)

                    ForEach(SampleData.rides.prefix(2)) { ride in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(ride.from) → \(ride.to)")
                                        .font(.headline)
                                        .foregroundStyle(Color.tmInk)
                                    Text("\(ride.date), \(ride.time)")
                                        .font(.caption)
                                        .foregroundStyle(Color.tmSlate)
                                }
                                Spacer()
                                Text("\(ride.seats) seats left")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.tmGreen)
                            }
                            HStack {
                                Label("$\(ride.price) / seat", systemImage: "dollarsign.circle.fill")
                                Spacer()
                                Label(ride.vehicle, systemImage: "car.fill")
                            }
                            .font(.caption)
                            .foregroundStyle(Color.tmSlate)
                        }
                        .padding(16)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
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

struct TripStatusCard: View {
    let status: String
    let title: String
    let detail: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.tmGreen)
                .frame(width: 38, height: 38)
                .background(Color.tmCloud)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(status)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.tmGreen)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.tmInk)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.tmSlate)
            }
            Spacer()
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
            Label(request.route, systemImage: "mappin.and.ellipse")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tmGreen)
            Text(request.note)
                .font(.subheadline)
                .foregroundStyle(Color.tmSlate)
            NavigationLink {
                DriverRequestDetailView(
                    request: request,
                    onAccept: onAccept,
                    onDecline: onDecline
                )
            } label: {
                Label("Details", systemImage: "doc.text.magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.tmGreen)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DriverRequestDetailView: View {
    let request: RideRequest
    let onAccept: () -> Void
    let onDecline: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                passengerSummary
                routeSection
                requestSection
                messageSection
            }
            .padding(20)
        }
        .background(Color.tmMist.ignoresSafeArea())
        .navigationTitle("Request details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
    }

    private var passengerSummary: some View {
        HStack(spacing: 14) {
            Avatar(initials: request.initials)
                .scaleEffect(1.15)
                .padding(.horizontal, 4)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(request.passenger)
                        .font(.title3.bold())
                        .foregroundStyle(Color.tmInk)
                    if request.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.tmGreen)
                    }
                }
                Text(request.verified ? "Identity verified" : "Identity not verified")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(request.verified ? Color.tmGreen : Color.tmAmber)
                HStack(spacing: 12) {
                    Label(request.completedTrips == 0 ? "New rider" : "\(request.completedTrips) trips", systemImage: "car.fill")
                    if request.completedTrips > 0 {
                        Label(String(format: "%.1f", request.rating), systemImage: "star.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(Color.tmSlate)
            }
            Spacer()
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var routeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            RequestDetailRow(icon: "location.fill", title: "Pickup", value: request.pickup)
            RequestDetailRow(icon: "mappin.and.ellipse", title: "Drop-off", value: request.dropoff)
            RequestDetailRow(icon: "calendar", title: "Departure", value: "\(request.departureDate) at \(request.departureTime)")
        }
        .requestDetailSection()
    }

    private var requestSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            RequestDetailRow(icon: "person.2.fill", title: "Seats requested", value: "\(request.seats)")
            RequestDetailRow(icon: "dollarsign.circle.fill", title: "Price", value: "$\(request.pricePerSeat) per seat")
            RequestDetailRow(icon: "banknote.fill", title: "Request total", value: "$\(request.pricePerSeat * request.seats)")
            RequestDetailRow(icon: "clock.fill", title: "Requested", value: request.requestedAt)
            RequestDetailRow(icon: "suitcase.fill", title: "Luggage", value: request.luggage)
        }
        .requestDetailSection()
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Passenger note", systemImage: "text.bubble.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tmGreen)
            Text(request.note)
                .font(.body)
                .foregroundStyle(Color.tmInk)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .requestDetailSection()
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                onDecline()
                dismiss()
            } label: {
                Label("Decline", systemImage: "xmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(Color.tmSlate)

            Button {
                onAccept()
                dismiss()
            } label: {
                Label("Accept", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.tmGreen)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

struct RequestDetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.tmGreen)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.tmSlate)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.tmInk)
            }
            Spacer()
        }
    }
}

private extension View {
    func requestDetailSection() -> some View {
        padding(16)
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
