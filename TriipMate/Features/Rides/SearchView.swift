import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var session: AppSession
    @State private var from = ""
    @State private var to = ""
    @State private var date = Date()
    @State private var useDateFilter = false
    @State private var seats = 1
    @State private var maxPrice = ""
    @State private var lowestPriceFirst = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    searchPanel
                    savingsBand
                    rideList
                }
                .padding(20)
            }
            .background(Color.tmMist.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) {
                RoleSwitchHeader()
            }
            .task {
                await session.loadSearchableRides()
            }
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
                    .disabled(!useDateFilter)
                    .opacity(useDateFilter ? 1 : 0.55)

                Stepper(value: $seats, in: 1...6) {
                    Label("\(seats)", systemImage: "person.2.fill")
                        .foregroundStyle(Color.tmInk)
                }
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 12) {
                Toggle("Date", isOn: $useDateFilter)
                    .toggleStyle(.switch)
                    .tint(Color.tmGreen)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.tmInk)
                    .padding(12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(Color.tmGreen)
                    TextField("Max price", text: $maxPrice)
                        .keyboardType(.numberPad)
                        .font(.body.weight(.semibold))
                        .onChange(of: maxPrice) { value in
                            maxPrice = String(value.filter { $0.isNumber }.prefix(4))
                        }
                }
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 10) {
                FilterChip(title: "Real rides", icon: "checkmark.seal.fill", isActive: true)
                FilterChip(title: "Open seats", icon: "person.2.fill", isActive: true)
                Button {
                    lowestPriceFirst.toggle()
                } label: {
                    FilterChip(title: "Lowest price", icon: "dollarsign.circle.fill", isActive: lowestPriceFirst)
                }
                .buttonStyle(.plain)
            }

            Button {
                Task { await session.loadSearchableRides() }
            } label: {
                if session.isRideSearchLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Label("Find rides", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.tmGreen)
            .disabled(session.isRideSearchLoading)
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
                Text(savingsText)
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
            HStack {
                Text("Recommended rides")
                    .font(.title3.bold())
                    .foregroundStyle(Color.tmInk)
                Spacer()
                Text("\(filteredRides.count)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.tmGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.tmGreen.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if session.isRideSearchLoading && session.searchableRides.isEmpty {
                loadingState
            } else if let authError = session.authError, session.searchableRides.isEmpty {
                retryState(message: authError)
            } else if filteredRides.isEmpty {
                emptyState
            } else {
                ForEach(filteredRides) { ride in
                    NavigationLink(value: ride.searchRide) {
                        RideCard(ride: ride.searchRide)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(for: Ride.self) { ride in
            RideDetailView(ride: ride)
        }
    }

    private var filteredRides: [MarketplaceRide] {
        var rides = session.searchableRides
            .filter { $0.availableSeats >= seats }
            .filter { !useDateFilter || Calendar.current.isDate($0.departureAt.date, inSameDayAs: date) }
            .filter { matchesPrice($0) }
            .filter { matches($0.from, query: from) }
            .filter { matches($0.to, query: to) }

        if lowestPriceFirst {
            rides.sort {
                if $0.pricePerSeatCents == $1.pricePerSeatCents {
                    return $0.departureAt.date < $1.departureAt.date
                }
                return $0.pricePerSeatCents < $1.pricePerSeatCents
            }
        } else {
            rides.sort { $0.departureAt.date < $1.departureAt.date }
        }

        return rides
    }

    private var savingsText: String {
        guard let cheapestRide = filteredRides.first else {
            return "Search real shared rides and compare your seat cost."
        }
        return "$\(cheapestRide.pricePerSeatCents / 100) per seat instead of about $500 solo"
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.tmGreen)
            Text("Loading real rides...")
                .font(.subheadline)
                .foregroundStyle(Color.tmSlate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.tmGreen)
            Text("No rides found")
                .font(.headline)
                .foregroundStyle(Color.tmInk)
            Text("Try a different city, date, seat count, or price.")
                .font(.subheadline)
                .foregroundStyle(Color.tmSlate)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func retryState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.tmAmber)
            Text("Could not load rides")
                .font(.headline)
                .foregroundStyle(Color.tmInk)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.tmSlate)
                .multilineTextAlignment(.center)
            Button {
                Task { await session.loadSearchableRides() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.tmGreen)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func matches(_ endpoint: RouteEndpoint, query: String) -> Bool {
        let normalizedQuery = query.normalizedSearchText
        guard !normalizedQuery.isEmpty else { return true }
        return endpoint.normalizedName.contains(normalizedQuery)
            || endpoint.city.normalizedSearchText.contains(normalizedQuery)
            || endpoint.state.normalizedSearchText.contains(normalizedQuery)
            || endpoint.displayName.normalizedSearchText.contains(normalizedQuery)
    }

    private func matchesPrice(_ ride: MarketplaceRide) -> Bool {
        guard let maxPriceValue = Int(maxPrice) else { return true }
        return ride.pricePerSeatCents / 100 <= maxPriceValue
    }
}

struct RouteField: View {
    let title: String
    @Binding var text: String
    let icon: String
    @FocusState private var isFocused: Bool

    private var suggestions: [NorthAmericaLocation] {
        NorthAmericaLocation.suggestions(matching: text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(Color.tmGreen)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(Color.tmSlate)
                    TextField("City, state or province", text: $text)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.tmInk)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                }
            }

            if isFocused && !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(suggestions) { location in
                        Button {
                            text = location.displayName
                            isFocused = false
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(Color.tmGreen)
                                    .frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(location.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.tmInk)
                                    Text("\(location.regionName), \(location.country)")
                                        .font(.caption)
                                        .foregroundStyle(Color.tmSlate)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        if location.id != suggestions.last?.id {
                            Divider()
                                .padding(.leading, 32)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct NorthAmericaLocation: Identifiable, Hashable {
    let city: String
    let regionCode: String
    let regionName: String
    let country: String

    var id: String { "\(city)-\(regionCode)-\(country)" }
    var displayName: String { "\(city), \(regionCode)" }

    static func suggestions(matching query: String) -> [NorthAmericaLocation] {
        let normalizedQuery = query.normalizedSearchText
        guard !normalizedQuery.isEmpty else { return [] }

        let matches = locations.filter { location in
            location.city.matchesAutocompletePrefix(normalizedQuery)
                || location.displayName.matchesAutocompletePrefix(normalizedQuery)
                || location.regionCode.matchesAutocompletePrefix(normalizedQuery)
                || location.regionName.matchesAutocompletePrefix(normalizedQuery)
        }

        return Array(matches.prefix(3))
    }

    private static let locations: [NorthAmericaLocation] = [
        .init(city: "Toronto", regionCode: "ON", regionName: "Ontario", country: "Canada"),
        .init(city: "Montreal", regionCode: "QC", regionName: "Quebec", country: "Canada"),
        .init(city: "Vancouver", regionCode: "BC", regionName: "British Columbia", country: "Canada"),
        .init(city: "Calgary", regionCode: "AB", regionName: "Alberta", country: "Canada"),
        .init(city: "Edmonton", regionCode: "AB", regionName: "Alberta", country: "Canada"),
        .init(city: "Ottawa", regionCode: "ON", regionName: "Ontario", country: "Canada"),
        .init(city: "Winnipeg", regionCode: "MB", regionName: "Manitoba", country: "Canada"),
        .init(city: "Quebec City", regionCode: "QC", regionName: "Quebec", country: "Canada"),
        .init(city: "Hamilton", regionCode: "ON", regionName: "Ontario", country: "Canada"),
        .init(city: "Kitchener", regionCode: "ON", regionName: "Ontario", country: "Canada"),
        .init(city: "London", regionCode: "ON", regionName: "Ontario", country: "Canada"),
        .init(city: "Halifax", regionCode: "NS", regionName: "Nova Scotia", country: "Canada"),
        .init(city: "Saskatoon", regionCode: "SK", regionName: "Saskatchewan", country: "Canada"),
        .init(city: "Regina", regionCode: "SK", regionName: "Saskatchewan", country: "Canada"),
        .init(city: "Victoria", regionCode: "BC", regionName: "British Columbia", country: "Canada"),
        .init(city: "New York", regionCode: "NY", regionName: "New York", country: "United States"),
        .init(city: "Los Angeles", regionCode: "CA", regionName: "California", country: "United States"),
        .init(city: "Chicago", regionCode: "IL", regionName: "Illinois", country: "United States"),
        .init(city: "Houston", regionCode: "TX", regionName: "Texas", country: "United States"),
        .init(city: "Phoenix", regionCode: "AZ", regionName: "Arizona", country: "United States"),
        .init(city: "Philadelphia", regionCode: "PA", regionName: "Pennsylvania", country: "United States"),
        .init(city: "San Antonio", regionCode: "TX", regionName: "Texas", country: "United States"),
        .init(city: "San Diego", regionCode: "CA", regionName: "California", country: "United States"),
        .init(city: "Dallas", regionCode: "TX", regionName: "Texas", country: "United States"),
        .init(city: "Austin", regionCode: "TX", regionName: "Texas", country: "United States"),
        .init(city: "Jacksonville", regionCode: "FL", regionName: "Florida", country: "United States"),
        .init(city: "San Jose", regionCode: "CA", regionName: "California", country: "United States"),
        .init(city: "Fort Worth", regionCode: "TX", regionName: "Texas", country: "United States"),
        .init(city: "Columbus", regionCode: "OH", regionName: "Ohio", country: "United States"),
        .init(city: "Charlotte", regionCode: "NC", regionName: "North Carolina", country: "United States"),
        .init(city: "San Francisco", regionCode: "CA", regionName: "California", country: "United States"),
        .init(city: "Indianapolis", regionCode: "IN", regionName: "Indiana", country: "United States"),
        .init(city: "Seattle", regionCode: "WA", regionName: "Washington", country: "United States"),
        .init(city: "Denver", regionCode: "CO", regionName: "Colorado", country: "United States"),
        .init(city: "Washington", regionCode: "DC", regionName: "District of Columbia", country: "United States"),
        .init(city: "Boston", regionCode: "MA", regionName: "Massachusetts", country: "United States"),
        .init(city: "Nashville", regionCode: "TN", regionName: "Tennessee", country: "United States"),
        .init(city: "Detroit", regionCode: "MI", regionName: "Michigan", country: "United States"),
        .init(city: "Pittsburgh", regionCode: "PA", regionName: "Pennsylvania", country: "United States"),
        .init(city: "Cleveland", regionCode: "OH", regionName: "Ohio", country: "United States"),
        .init(city: "Buffalo", regionCode: "NY", regionName: "New York", country: "United States"),
        .init(city: "Minneapolis", regionCode: "MN", regionName: "Minnesota", country: "United States"),
        .init(city: "Portland", regionCode: "OR", regionName: "Oregon", country: "United States"),
        .init(city: "Miami", regionCode: "FL", regionName: "Florida", country: "United States"),
        .init(city: "Atlanta", regionCode: "GA", regionName: "Georgia", country: "United States")
    ]
}

private extension MarketplaceRide {
    var searchRide: Ride {
        Ride(
            id: id,
            driver: driverDisplayName,
            initials: driverDisplayName.initials,
            from: from.displayName,
            to: to.displayName,
            date: Self.dateFormatter.string(from: departureAt.date),
            time: Self.timeFormatter.string(from: departureAt.date),
            endTime: expectedArrivalAt.map { Self.timeFormatter.string(from: $0.date) } ?? "Not set",
            tripTime: durationSummary,
            seats: availableSeats,
            totalSeats: totalSeats,
            price: pricePerSeatCents / 100,
            vehicle: vehicle.shortName,
            carMake: vehicle.make,
            carModel: vehicle.model,
            carYear: vehicle.year,
            powerType: vehicle.powerType,
            bodyType: vehicle.bodyType,
            rating: 5.0,
            verified: false,
            notes: notes
        )
    }

    private var durationSummary: String {
        let hours = estimatedDurationMinutes / 60
        let minutes = estimatedDurationMinutes % 60
        if hours == 0 { return "\(minutes)m" }
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

private extension VehicleSnapshot {
    var shortName: String {
        "\(make) \(model)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension String {
    var normalizedSearchText: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func matchesAutocompletePrefix(_ query: String) -> Bool {
        let normalizedValue = normalizedSearchText
        guard !query.isEmpty else { return false }
        return normalizedValue.hasPrefix(query)
            || normalizedValue
                .split(separator: " ")
                .contains { $0.hasPrefix(query) }
    }

    var initials: String {
        split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isActive: Bool

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isActive ? Color.tmGreen : Color.tmSlate)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isActive ? Color.white : Color.tmMist)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? Color.tmGreen.opacity(0.35) : Color.tmLine, lineWidth: 1)
            )
    }
}
