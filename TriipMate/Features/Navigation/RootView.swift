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
                if selectedTab != .profile {
                    selectedTab = .home
                }
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
    @EnvironmentObject private var session: AppSession
    @State private var isShowingRoleError = false

    private var activeRole: AppRole { session.activeRole }

    var body: some View {
        HStack {
            Spacer()
            Button {
                Task {
                    let nextRole: AppRole = activeRole == .passenger ? .driver : .passenger
                    await session.updateRole(nextRole)
                    isShowingRoleError = session.profileError != nil
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
                    .opacity(session.isRoleUpdating ? 0.35 : 1)

                    if session.isRoleUpdating {
                        ProgressView()
                            .tint(Color.tmGreen)
                    }
                }
                .frame(width: 88, height: 36)
                .animation(.spring(response: 0.38, dampingFraction: 0.86), value: activeRole)
            }
            .buttonStyle(.plain)
            .disabled(session.isRoleUpdating)
            .accessibilityLabel("Switch travel mode")
            .accessibilityValue(activeRole.title)
            .alert("Could not change mode", isPresented: $isShowingRoleError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(session.profileError ?? "Try again when the local Firebase server is available.")
            }
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
                RoleSwitchHeader()
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
                RoleSwitchHeader()
            }
        }
    }
}

struct PostedTripsView: View {
    @EnvironmentObject private var session: AppSession
    @State private var selectedStatus: RideStatus?
    @State private var rideToEdit: MarketplaceRide?
    @State private var pendingAction: DriverRideAction?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    statusFilter

                    if session.isDriverRidesLoading {
                        loadingState
                    } else if filteredRides.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredRides) { ride in
                            NavigationLink {
                                DriverRideDetailView(
                                    ride: ride,
                                    onEdit: { rideToEdit = ride },
                                    onCancel: { pendingAction = .cancel(ride) },
                                    onDelete: { pendingAction = .delete(ride) }
                                )
                            } label: {
                                DriverRideCard(ride: ride)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.tmMist.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) {
                RoleSwitchHeader()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await session.loadDriverRides() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(session.isDriverRidesLoading)
                }
            }
            .task {
                await session.loadDriverRides()
            }
            .sheet(item: $rideToEdit) { ride in
                DriverRideEditView(ride: ride) { updatedRide in
                    await session.updateDriverRide(updatedRide)
                }
            }
            .alert(item: $pendingAction) { action in
                switch action {
                case .cancel(let ride):
                    return Alert(
                        title: Text("Cancel ride?"),
                        message: Text("Passengers will no longer be able to request this ride."),
                        primaryButton: .destructive(Text("Cancel ride")) {
                            Task { await session.cancelDriverRide(ride) }
                        },
                        secondaryButton: .cancel()
                    )
                case .delete(let ride):
                    return Alert(
                        title: Text("Delete ride?"),
                        message: Text("This removes the ride from Firestore. Completed or cancelled history should normally be kept."),
                        primaryButton: .destructive(Text("Delete")) {
                            Task { await session.deleteDriverRide(ride) }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }

    private var filteredRides: [MarketplaceRide] {
        guard let selectedStatus else { return session.driverRides }
        return session.driverRides.filter { $0.status == selectedStatus }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My posted rides")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.tmInk)
            Text("View, edit, cancel, or delete the rides you published.")
                .font(.subheadline)
                .foregroundStyle(Color.tmSlate)
        }
    }

    private var statusFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                DriverRideStatusChip(
                    title: "All",
                    count: session.driverRides.count,
                    isSelected: selectedStatus == nil
                ) {
                    selectedStatus = nil
                }

                ForEach(RideStatus.allCases) { status in
                    DriverRideStatusChip(
                        title: status.displayTitle,
                        count: session.driverRides.filter { $0.status == status }.count,
                        isSelected: selectedStatus == status
                    ) {
                        selectedStatus = status
                    }
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.tmGreen)
            Text("Loading your posted rides...")
                .font(.subheadline)
                .foregroundStyle(Color.tmSlate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "car.2")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.tmGreen)
            Text(selectedStatus == nil ? "No posted rides yet" : "No \(selectedStatus?.displayTitle.lowercased() ?? "") rides")
                .font(.headline)
                .foregroundStyle(Color.tmInk)
            Text("Published rides from the Post Ride tab will appear here.")
                .font(.subheadline)
                .foregroundStyle(Color.tmSlate)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct DriverRideStatusChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Text("\(count)")
                    .font(.caption2.bold())
                    .foregroundStyle(isSelected ? Color.tmGreen : Color.tmSlate)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(isSelected ? .white : Color.tmMist)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? .white : Color.tmSlate)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isSelected ? Color.tmGreen : .white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.tmGreen : Color.tmLine, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct DriverRideCard: View {
    let ride: MarketplaceRide

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(ride.from.displayName) to \(ride.to.displayName)")
                        .font(.headline)
                        .foregroundStyle(Color.tmInk)
                    Text(ride.departureSummary)
                        .font(.caption)
                        .foregroundStyle(Color.tmSlate)
                }
                Spacer()
                Text(ride.status.displayTitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ride.status.tint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(ride.status.tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 12) {
                DriverRideMetric(icon: "person.2.fill", value: "\(ride.availableSeats)/\(ride.totalSeats)", label: "Seats")
                DriverRideMetric(icon: "dollarsign.circle.fill", value: ride.priceSummary, label: "Per seat")
                DriverRideMetric(icon: "car.fill", value: ride.vehicle.shortName, label: "Vehicle")
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.tmLine, lineWidth: 1)
        }
    }
}

private struct DriverRideMetric: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(value, systemImage: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.tmInk)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.tmSlate)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DriverRideDetailView: View {
    let ride: MarketplaceRide
    let onEdit: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(ride.from.displayName) to \(ride.to.displayName)")
                            .font(.title3.bold())
                            .foregroundStyle(Color.tmInk)
                        Spacer()
                        Text(ride.status.displayTitle)
                            .font(.caption.bold())
                            .foregroundStyle(ride.status.tint)
                    }
                    Text(ride.departureSummary)
                        .font(.subheadline)
                        .foregroundStyle(Color.tmSlate)
                }
                .requestDetailSection()

                VStack(alignment: .leading, spacing: 14) {
                    RequestDetailRow(icon: "location.fill", title: "From", value: ride.from.displayName)
                    RequestDetailRow(icon: "mappin.and.ellipse", title: "To", value: ride.to.displayName)
                    RequestDetailRow(icon: "clock.fill", title: "Expected end", value: ride.arrivalSummary)
                    RequestDetailRow(icon: "timer", title: "Trip time", value: ride.durationSummary)
                    RequestDetailRow(icon: "person.2.fill", title: "Seats", value: "\(ride.availableSeats) open of \(ride.totalSeats)")
                    RequestDetailRow(icon: "dollarsign.circle.fill", title: "Seat price", value: ride.priceSummary)
                }
                .requestDetailSection()

                VStack(alignment: .leading, spacing: 14) {
                    RequestDetailRow(icon: "car.fill", title: "Car", value: ride.vehicle.displayName)
                    RequestDetailRow(icon: "fuelpump.fill", title: "Power", value: ride.vehicle.powerType)
                    RequestDetailRow(icon: "rectangle.3.group.fill", title: "Body", value: ride.vehicle.bodyType)
                }
                .requestDetailSection()

                VStack(alignment: .leading, spacing: 8) {
                    Label("Driver note", systemImage: "text.bubble.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.tmGreen)
                    Text(ride.notes.isEmpty ? "No note added." : ride.notes)
                        .font(.body)
                        .foregroundStyle(Color.tmInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .requestDetailSection()
            }
            .padding(20)
        }
        .background(Color.tmMist.ignoresSafeArea())
        .navigationTitle("Ride details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .tint(Color.red)

                Button(action: onCancel) {
                    Label("Cancel", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Color.tmSlate)
                .disabled(ride.status == .cancelled || ride.status == .completed)

                Button(action: onEdit) {
                    Label("Edit", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.tmGreen)
                .disabled(ride.status == .completed || ride.status == .cancelled)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }
}

private struct DriverRideEditView: View {
    let ride: MarketplaceRide
    let onSave: (MarketplaceRide) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var availableSeats: Int
    @State private var totalSeats: Int
    @State private var price: Double
    @State private var status: RideStatus
    @State private var notes: String
    @State private var error: String?
    @State private var isSaving = false

    init(ride: MarketplaceRide, onSave: @escaping (MarketplaceRide) async -> Bool) {
        self.ride = ride
        self.onSave = onSave
        _availableSeats = State(initialValue: ride.availableSeats)
        _totalSeats = State(initialValue: ride.totalSeats)
        _price = State(initialValue: Double(ride.pricePerSeatCents / 100))
        _status = State(initialValue: ride.status)
        _notes = State(initialValue: ride.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ride") {
                    Text("\(ride.from.displayName) to \(ride.to.displayName)")
                    Text(ride.departureSummary)
                        .foregroundStyle(Color.tmSlate)
                }

                Section("Seats and price") {
                    Stepper("Total seats: \(totalSeats)", value: $totalSeats, in: 1...8)
                        .onChange(of: totalSeats) { value in
                            availableSeats = min(availableSeats, value)
                        }
                    Stepper("Available seats: \(availableSeats)", value: $availableSeats, in: 0...totalSeats)
                    Stepper("$\(Int(price)) per seat", value: $price, in: 25...1500, step: 1)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(RideStatus.allCases) { status in
                            Text(status.displayTitle).tag(status)
                        }
                    }
                }

                Section("Note") {
                    TextField("Driver note", text: $notes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .navigationTitle("Edit ride")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        guard availableSeats <= totalSeats else {
            error = "Available seats cannot be more than total seats."
            return
        }

        isSaving = true
        error = nil
        let updatedRide = ride.updated(
            status: status,
            availableSeats: availableSeats,
            totalSeats: totalSeats,
            pricePerSeatCents: Int(price.rounded()) * 100,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if await onSave(updatedRide) {
            dismiss()
        } else {
            error = "The ride could not be saved."
        }
        isSaving = false
    }
}

private enum DriverRideAction: Identifiable {
    case cancel(MarketplaceRide)
    case delete(MarketplaceRide)

    var id: String {
        switch self {
        case .cancel(let ride):
            return "cancel-\(ride.id)"
        case .delete(let ride):
            return "delete-\(ride.id)"
        }
    }
}

private extension MarketplaceRide {
    var departureSummary: String {
        Self.shortDateFormatter.string(from: departureAt.date)
    }

    var arrivalSummary: String {
        guard let expectedArrivalAt else {
            return "Not set"
        }
        return Self.shortDateFormatter.string(from: expectedArrivalAt.date)
    }

    var durationSummary: String {
        let hours = estimatedDurationMinutes / 60
        let minutes = estimatedDurationMinutes % 60
        if hours == 0 {
            return "\(minutes)m"
        }
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }

    var priceSummary: String {
        "$\(pricePerSeatCents / 100)"
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
}

private extension RideStatus {
    var displayTitle: String {
        switch self {
        case .draft:
            return "Draft"
        case .published:
            return "Published"
        case .active:
            return "Active"
        case .full:
            return "Full"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }

    var tint: Color {
        switch self {
        case .draft:
            return Color.tmSlate
        case .published, .active:
            return Color.tmGreen
        case .full:
            return Color.tmAmber
        case .completed:
            return Color.tmInk
        case .cancelled:
            return Color.red
        }
    }
}

private extension VehicleSnapshot {
    var displayName: String {
        "\(year) \(make) \(model)".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var shortName: String {
        "\(make) \(model)".trimmingCharacters(in: .whitespacesAndNewlines)
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
