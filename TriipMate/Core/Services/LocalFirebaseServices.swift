import Foundation

struct LocalStorageProfilePhotoService {
    private let bucket = "demo-triipmate-local.appspot.com"

    private var baseURL: URL {
        URL(string: "http://127.0.0.1:9199/v0/b/\(bucket)/o")!
    }

    func upload(imageData: Data, path: String, idToken: String) async throws {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "uploadType", value: "media"),
            URLQueryItem(name: "name", value: path)
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = imageData

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw LocalAuthError.invalidResponse
        }
    }

    func download(path: String, idToken: String) async throws -> Data {
        let encodedPath = path.storagePathEncoded
        var components = URLComponents(string: "\(baseURL.absoluteString)/\(encodedPath)")!
        components.queryItems = [URLQueryItem(name: "alt", value: "media")]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw LocalAuthError.invalidResponse
        }
        return data
    }
}

private extension String {
    var storagePathEncoded: String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}

struct LocalFirestoreProfileService {
    private let projectId = "demo-triipmate-local"

    private var baseURL: URL {
        URL(string: "http://127.0.0.1:8080/v1/projects/\(projectId)/databases/(default)/documents/users")!
    }

    func save(_ profile: UserProfile, idToken: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent(profile.uid))
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(FirestoreUserDocument(fields: .init(profile: profile)))

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw LocalAuthError.invalidResponse
        }
    }

    func fetch(uid: String, idToken: String) async throws -> UserProfile {
        var request = URLRequest(url: baseURL.appendingPathComponent(uid))
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LocalAuthError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            throw LocalAuthError.profileNotFound
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw LocalAuthError.invalidResponse
        }

        let document = try JSONDecoder().decode(FirestoreUserDocument.self, from: data)
        return document.fields.profile(uid: uid)
    }
}

struct LocalFirestoreVehicleService {
    private let projectId = "demo-triipmate-local"

    private var usersURL: URL {
        URL(string: "http://127.0.0.1:8080/v1/projects/\(projectId)/databases/(default)/documents/users")!
    }

    func save(_ vehicle: SavedVehicle, uid: String, idToken: String) async throws {
        let url = usersURL
            .appendingPathComponent(uid)
            .appendingPathComponent("vehicles")
            .appendingPathComponent(vehicle.id)
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            FirestoreVehicleDocument(fields: [
                "make": FirestoreStringValue(stringValue: vehicle.make),
                "model": FirestoreStringValue(stringValue: vehicle.model),
                "year": FirestoreStringValue(stringValue: vehicle.year),
                "powerType": FirestoreStringValue(stringValue: vehicle.powerType),
                "bodyType": FirestoreStringValue(stringValue: vehicle.bodyType)
            ])
        )

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw LocalAuthError.invalidResponse
        }
    }

    func fetchAll(uid: String, idToken: String) async throws -> [SavedVehicle] {
        let url = usersURL.appendingPathComponent(uid).appendingPathComponent("vehicles")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw LocalAuthError.invalidResponse
        }

        let collection = try JSONDecoder().decode(FirestoreVehicleCollection.self, from: data)
        return (collection.documents ?? []).compactMap { document in
            let fields = document.fields
            guard let make = fields["make"]?.stringValue,
                  let model = fields["model"]?.stringValue,
                  let year = fields["year"]?.stringValue else {
                return nil
            }
            return SavedVehicle(
                id: document.name?.split(separator: "/").last.map(String.init) ?? UUID().uuidString,
                make: make,
                model: model,
                year: year,
                powerType: fields["powerType"]?.stringValue ?? "Fuel",
                bodyType: fields["bodyType"]?.stringValue ?? "Sedan"
            )
        }
        .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}

struct LocalFirestoreRideService {
    private let projectId = "demo-triipmate-local"

    private var ridesURL: URL {
        URL(string: "http://127.0.0.1:8080/v1/projects/\(projectId)/databases/(default)/documents/rides")!
    }

    func save(_ ride: MarketplaceRide, idToken: String) async throws {
        var request = URLRequest(url: ridesURL.appendingPathComponent(ride.id))
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(FirestoreRideDocument(ride: ride))

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw LocalAuthError.invalidResponse
        }
    }

    func fetchDriverRides(uid: String, idToken: String) async throws -> [MarketplaceRide] {
        var request = URLRequest(url: ridesURL)
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LocalAuthError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            return []
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw LocalAuthError.invalidResponse
        }

        let collection = try JSONDecoder().decode(FirestoreRideCollection.self, from: data)
        return (collection.documents ?? [])
            .compactMap { $0.marketplaceRide }
            .filter { $0.driverUid == uid }
            .sorted { $0.departureAt.date < $1.departureAt.date }
    }

    func deleteRide(id: String, idToken: String) async throws {
        var request = URLRequest(url: ridesURL.appendingPathComponent(id))
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw LocalAuthError.invalidResponse
        }
    }
}

private struct FirestoreVehicleDocument: Codable {
    let name: String?
    let fields: [String: FirestoreStringValue]

    init(name: String? = nil, fields: [String: FirestoreStringValue]) {
        self.name = name
        self.fields = fields
    }
}

private struct FirestoreVehicleCollection: Decodable {
    let documents: [FirestoreVehicleDocument]?
}

private struct FirestoreUserDocument: Codable {
    let fields: FirestoreUserFields
}

private struct FirestoreUserFields: Codable {
    let firstName: FirestoreStringValue
    let lastName: FirestoreStringValue
    let email: FirestoreStringValue
    let phone: FirestoreStringValue
    let role: FirestoreStringValue
    let profilePhotoPath: FirestoreStringValue?
    let updatedAt: FirestoreStringValue?

    init(profile: UserProfile) {
        firstName = FirestoreStringValue(stringValue: profile.firstName)
        lastName = FirestoreStringValue(stringValue: profile.lastName)
        email = FirestoreStringValue(stringValue: profile.email)
        phone = FirestoreStringValue(stringValue: profile.phone)
        role = FirestoreStringValue(stringValue: profile.role.rawValue)
        profilePhotoPath = profile.profilePhotoPath.map(FirestoreStringValue.init(stringValue:))
        updatedAt = FirestoreStringValue(stringValue: ISO8601DateFormatter().string(from: Date()))
    }

    func profile(uid: String) -> UserProfile {
        UserProfile(
            uid: uid,
            firstName: firstName.stringValue,
            lastName: lastName.stringValue,
            email: email.stringValue,
            phone: phone.stringValue,
            role: AppRole(rawValue: role.stringValue) ?? .passenger,
            profilePhotoPath: profilePhotoPath?.stringValue
        )
    }
}

private struct FirestoreStringValue: Codable {
    let stringValue: String
}

private struct FirestoreRideDocument: Encodable {
    let fields: [String: FirestoreRideValue]

    init(ride: MarketplaceRide) {
        var rideFields: [String: FirestoreRideValue] = [
            "driverUid": .string(ride.driverUid),
            "driverDisplayName": .string(ride.driverDisplayName),
            "from": .map(ride.from.firestoreFields),
            "to": .map(ride.to.firestoreFields),
            "departureAt": .timestamp(ride.departureAt.date),
            "estimatedDurationMinutes": .integer(ride.estimatedDurationMinutes),
            "availableSeats": .integer(ride.availableSeats),
            "totalSeats": .integer(ride.totalSeats),
            "pricePerSeatCents": .integer(ride.pricePerSeatCents),
            "vehicle": .map(ride.vehicle.firestoreFields),
            "status": .string(ride.status.rawValue),
            "notes": .string(ride.notes),
            "createdAt": .timestamp(ride.createdAt.date),
            "updatedAt": .timestamp(ride.updatedAt.date)
        ]

        if let driverProfilePhotoPath = ride.driverProfilePhotoPath {
            rideFields["driverProfilePhotoPath"] = .string(driverProfilePhotoPath)
        }

        if let expectedArrivalAt = ride.expectedArrivalAt {
            rideFields["expectedArrivalAt"] = .timestamp(expectedArrivalAt.date)
        }

        fields = rideFields
    }
}

private enum FirestoreRideValue: Encodable {
    case string(String)
    case integer(Int)
    case timestamp(Date)
    case map([String: FirestoreRideValue])

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .string(let value):
            try container.encode(value, forKey: .stringValue)
        case .integer(let value):
            try container.encode(String(value), forKey: .integerValue)
        case .timestamp(let date):
            try container.encode(Self.timestampFormatter.string(from: date), forKey: .timestampValue)
        case .map(let fields):
            try container.encode(FirestoreMapValue(fields: fields), forKey: .mapValue)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case stringValue
        case integerValue
        case timestampValue
        case mapValue
    }

    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

private struct FirestoreMapValue: Encodable {
    let fields: [String: FirestoreRideValue]
}

private struct FirestoreRideCollection: Decodable {
    let documents: [FirestoreDecodedRideDocument]?
}

private struct FirestoreDecodedRideDocument: Decodable {
    let name: String?
    let fields: [String: FirestoreDecodedValue]

    var marketplaceRide: MarketplaceRide? {
        let id = name?.split(separator: "/").last.map(String.init) ?? UUID().uuidString
        guard let driverUid = fields["driverUid"]?.stringValue,
              let driverDisplayName = fields["driverDisplayName"]?.stringValue,
              let from = fields["from"]?.routeEndpoint,
              let to = fields["to"]?.routeEndpoint,
              let departureAt = fields["departureAt"]?.timestamp,
              let estimatedDurationMinutes = fields["estimatedDurationMinutes"]?.intValue,
              let availableSeats = fields["availableSeats"]?.intValue,
              let totalSeats = fields["totalSeats"]?.intValue,
              let pricePerSeatCents = fields["pricePerSeatCents"]?.intValue,
              let vehicle = fields["vehicle"]?.vehicleSnapshot,
              let statusRawValue = fields["status"]?.stringValue,
              let status = RideStatus(rawValue: statusRawValue),
              let notes = fields["notes"]?.stringValue,
              let createdAt = fields["createdAt"]?.timestamp,
              let updatedAt = fields["updatedAt"]?.timestamp else {
            return nil
        }

        return MarketplaceRide(
            id: id,
            driverUid: driverUid,
            driverDisplayName: driverDisplayName,
            driverProfilePhotoPath: fields["driverProfilePhotoPath"]?.stringValue,
            from: from,
            to: to,
            departureAt: departureAt,
            expectedArrivalAt: fields["expectedArrivalAt"]?.timestamp,
            estimatedDurationMinutes: estimatedDurationMinutes,
            availableSeats: availableSeats,
            totalSeats: totalSeats,
            pricePerSeatCents: pricePerSeatCents,
            vehicle: vehicle,
            status: status,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private struct FirestoreDecodedValue: Decodable {
    let stringValue: String?
    let integerValue: String?
    let timestampValue: String?
    let mapValue: FirestoreDecodedMapValue?

    var intValue: Int? {
        integerValue.flatMap(Int.init)
    }

    var timestamp: FirestoreTimestamp? {
        guard let timestampValue,
              let date = Self.date(from: timestampValue) else {
            return nil
        }
        return FirestoreTimestamp(date: date)
    }

    var routeEndpoint: RouteEndpoint? {
        guard let fields = mapValue?.fields,
              let city = fields["city"]?.stringValue,
              let state = fields["state"]?.stringValue,
              let displayName = fields["displayName"]?.stringValue,
              let normalizedName = fields["normalizedName"]?.stringValue else {
            return nil
        }
        return RouteEndpoint(
            city: city,
            state: state,
            displayName: displayName,
            normalizedName: normalizedName
        )
    }

    var vehicleSnapshot: VehicleSnapshot? {
        guard let fields = mapValue?.fields,
              let make = fields["make"]?.stringValue,
              let model = fields["model"]?.stringValue,
              let year = fields["year"]?.stringValue,
              let powerType = fields["powerType"]?.stringValue,
              let bodyType = fields["bodyType"]?.stringValue else {
            return nil
        }
        return VehicleSnapshot(
            vehicleId: fields["vehicleId"]?.stringValue,
            make: make,
            model: model,
            year: year,
            powerType: powerType,
            bodyType: bodyType
        )
    }

    private static func date(from timestamp: String) -> Date? {
        fractionalTimestampFormatter.date(from: timestamp) ?? wholeSecondTimestampFormatter.date(from: timestamp)
    }

    private static let fractionalTimestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let wholeSecondTimestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

private struct FirestoreDecodedMapValue: Decodable {
    let fields: [String: FirestoreDecodedValue]?
}

private extension RouteEndpoint {
    var firestoreFields: [String: FirestoreRideValue] {
        [
            "city": .string(city),
            "state": .string(state),
            "displayName": .string(displayName),
            "normalizedName": .string(normalizedName)
        ]
    }
}

private extension VehicleSnapshot {
    var firestoreFields: [String: FirestoreRideValue] {
        var fields: [String: FirestoreRideValue] = [
            "make": .string(make),
            "model": .string(model),
            "year": .string(year),
            "powerType": .string(powerType),
            "bodyType": .string(bodyType)
        ]

        if let vehicleId {
            fields["vehicleId"] = .string(vehicleId)
        }

        return fields
    }
}

struct LocalFirebaseAuthService {
    private let baseURL = URL(string: "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1")!
    private let tokenURL = URL(string: "http://127.0.0.1:9099/securetoken.googleapis.com/v1/token")!
    private let apiKey = "triipmate-local"

    func register(email: String, password: String) async throws -> AuthUser {
        try await sendAuthRequest(endpoint: "accounts:signUp", email: email, password: password)
    }

    func login(email: String, password: String) async throws -> AuthUser {
        try await sendAuthRequest(endpoint: "accounts:signInWithPassword", email: email, password: password)
    }

    func restore(refreshToken: String) async throws -> AuthUser {
        var components = URLComponents(url: tokenURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var formAllowedCharacters = CharacterSet.alphanumerics
        formAllowedCharacters.insert(charactersIn: "-._~")
        let encodedToken = refreshToken.addingPercentEncoding(withAllowedCharacters: formAllowedCharacters) ?? refreshToken
        request.httpBody = Data("grant_type=refresh_token&refresh_token=\(encodedToken)".utf8)

        let tokenResponse: TokenRefreshResponse = try await decodedResponse(for: request)
        let account = try await lookup(idToken: tokenResponse.idToken)
        return AuthUser(
            uid: tokenResponse.userId,
            email: account.email,
            idToken: tokenResponse.idToken,
            refreshToken: tokenResponse.refreshToken
        )
    }

    func sendPasswordReset(email: String) async throws {
        var components = URLComponents(url: baseURL.appendingPathComponent("accounts:sendOobCode"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            PasswordResetRequest(requestType: "PASSWORD_RESET", email: email)
        )

        let _: PasswordResetResponse = try await decodedResponse(for: request)
    }

    func updateEmail(idToken: String, email: String) async throws -> AuthUser {
        var components = URLComponents(url: baseURL.appendingPathComponent("accounts:update"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            UpdateEmailRequest(idToken: idToken, email: email, returnSecureToken: true)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LocalAuthError.invalidResponse
        }

        if (200..<300).contains(httpResponse.statusCode) {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            return AuthUser(
                uid: authResponse.localId,
                email: authResponse.email,
                idToken: authResponse.idToken,
                refreshToken: authResponse.refreshToken
            )
        }

        if let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
            throw LocalAuthError.server(errorResponse.error.message.authFriendlyMessage)
        }

        throw LocalAuthError.invalidResponse
    }

    private func sendAuthRequest(endpoint: String, email: String, password: String) async throws -> AuthUser {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AuthRequest(email: email, password: password, returnSecureToken: true))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LocalAuthError.invalidResponse
        }

        if (200..<300).contains(httpResponse.statusCode) {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            return AuthUser(
                uid: authResponse.localId,
                email: authResponse.email,
                idToken: authResponse.idToken,
                refreshToken: authResponse.refreshToken
            )
        }

        if let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
            throw LocalAuthError.server(errorResponse.error.message.authFriendlyMessage)
        }

        throw LocalAuthError.invalidResponse
    }

    private func lookup(idToken: String) async throws -> AccountLookupUser {
        var components = URLComponents(url: baseURL.appendingPathComponent("accounts:lookup"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AccountLookupRequest(idToken: idToken))

        let response: AccountLookupResponse = try await decodedResponse(for: request)
        guard let user = response.users.first else {
            throw LocalAuthError.invalidResponse
        }
        return user
    }

    private func decodedResponse<Response: Decodable>(for request: URLRequest) async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LocalAuthError.invalidResponse
        }
        if (200..<300).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(Response.self, from: data)
        }
        if let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
            throw LocalAuthError.server(errorResponse.error.message.authFriendlyMessage)
        }
        throw LocalAuthError.invalidResponse
    }
}

private struct AuthRequest: Encodable {
    let email: String
    let password: String
    let returnSecureToken: Bool
}

private struct UpdateEmailRequest: Encodable {
    let idToken: String
    let email: String
    let returnSecureToken: Bool
}

private struct AuthResponse: Decodable {
    let localId: String
    let email: String
    let idToken: String
    let refreshToken: String
}

private struct TokenRefreshResponse: Decodable {
    let userId: String
    let idToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case idToken = "id_token"
        case refreshToken = "refresh_token"
    }
}

private struct AccountLookupRequest: Encodable {
    let idToken: String
}

private struct AccountLookupResponse: Decodable {
    let users: [AccountLookupUser]
}

private struct AccountLookupUser: Decodable {
    let localId: String
    let email: String
}

private struct PasswordResetRequest: Encodable {
    let requestType: String
    let email: String
}

private struct PasswordResetResponse: Decodable {
    let email: String
}

private struct AuthErrorResponse: Decodable {
    let error: AuthErrorBody
}

private struct AuthErrorBody: Decodable {
    let message: String
}

private extension String {
    var authFriendlyMessage: String {
        switch self {
        case "EMAIL_EXISTS":
            return "This email is already registered. Try logging in."
        case "EMAIL_NOT_FOUND", "INVALID_LOGIN_CREDENTIALS":
            return "No account found with this email and password."
        case "INVALID_PASSWORD":
            return "Incorrect password."
        case "WEAK_PASSWORD : Password should be at least 6 characters":
            return "Password should be at least 6 characters."
        case "INVALID_REFRESH_TOKEN", "TOKEN_EXPIRED", "USER_DISABLED", "USER_NOT_FOUND":
            return "Your saved session has expired. Please log in again."
        default:
            return replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
