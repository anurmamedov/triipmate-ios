import Foundation

struct AuthUser {
    let uid: String
    let email: String
    let idToken: String
    let refreshToken: String
}

struct UserProfile {
    let uid: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let countryCode: String
    let role: AppRole
    let profilePhotoPath: String?
    let ratingAverage: Double?
    let ratingCount: Int
    let completedTripCount: Int
    let totalSavingsCents: Int
    let isIdentityVerified: Bool
    let isDriverVerified: Bool

    init(
        uid: String,
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        countryCode: String = "CA",
        role: AppRole,
        profilePhotoPath: String?,
        ratingAverage: Double? = nil,
        ratingCount: Int = 0,
        completedTripCount: Int = 0,
        totalSavingsCents: Int = 0,
        isIdentityVerified: Bool = false,
        isDriverVerified: Bool = false
    ) {
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.countryCode = countryCode
        self.role = role
        self.profilePhotoPath = profilePhotoPath
        self.ratingAverage = ratingAverage
        self.ratingCount = ratingCount
        self.completedTripCount = completedTripCount
        self.totalSavingsCents = totalSavingsCents
        self.isIdentityVerified = isIdentityVerified
        self.isDriverVerified = isDriverVerified
    }
}

extension UserProfile {
    static func countryCode(fromPhone phone: String) -> String {
        if phone.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("+1") {
            return "CA"
        }
        return Locale.current.region?.identifier == "US" ? "US" : "CA"
    }

    func updated(
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        countryCode: String? = nil,
        role: AppRole? = nil,
        profilePhotoPath: String? = nil,
        replacesProfilePhotoPath: Bool = false
    ) -> UserProfile {
        UserProfile(
            uid: uid,
            firstName: firstName ?? self.firstName,
            lastName: lastName ?? self.lastName,
            email: email ?? self.email,
            phone: phone ?? self.phone,
            countryCode: countryCode ?? self.countryCode,
            role: role ?? self.role,
            profilePhotoPath: replacesProfilePhotoPath ? profilePhotoPath : self.profilePhotoPath,
            ratingAverage: ratingAverage,
            ratingCount: ratingCount,
            completedTripCount: completedTripCount,
            totalSavingsCents: totalSavingsCents,
            isIdentityVerified: isIdentityVerified,
            isDriverVerified: isDriverVerified
        )
    }
}

enum CurrencySupport {
    static func code(forCountryCode countryCode: String?) -> String {
        switch countryCode?.uppercased() {
        case "US":
            return "USD"
        case "CA":
            return "CAD"
        default:
            return Locale.current.region?.identifier == "US" ? "USD" : "CAD"
        }
    }

    static func code(forRegionCode regionCode: String) -> String {
        canadianProvinceCodes.contains(regionCode.uppercased()) ? "CAD" : "USD"
    }

    static func format(cents: Int, countryCode: String?) -> String {
        format(dollars: Double(cents) / 100, currencyCode: code(forCountryCode: countryCode))
    }

    static func format(cents: Int, regionCode: String) -> String {
        format(dollars: Double(cents) / 100, currencyCode: code(forRegionCode: regionCode))
    }

    static func format(dollars: Double, currencyCode: String) -> String {
        dollars.formatted(
            .currency(code: currencyCode)
                .precision(.fractionLength(0))
                .presentation(.narrow)
        )
    }

    private static let canadianProvinceCodes: Set<String> = [
        "AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT"
    ]
}

struct SavedVehicle: Identifiable, Hashable {
    let id: String
    let make: String
    let model: String
    let year: String
    let powerType: String
    let bodyType: String
    let isDefault: Bool

    var displayName: String {
        "\(year) \(make) \(model)".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var duplicateKey: String {
        [make, model, year, powerType, bodyType]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .joined(separator: "|")
    }
}

enum LocalAuthError: LocalizedError {
    case invalidResponse
    case server(String)
    case profileNotFound
    case invalidInput(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The local Firebase emulator returned an unexpected response."
        case .server(let message):
            return message
        case .profileNotFound:
            return "We could not find your local profile data."
        case .invalidInput(let message):
            return message
        }
    }
}

enum AuthValidator {
    static func normalizedEmail(_ email: String) throws -> String {
        let value = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2,
              !parts[0].isEmpty,
              parts[1].contains("."),
              !parts[1].hasPrefix("."),
              !parts[1].hasSuffix(".") else {
            throw LocalAuthError.invalidInput("Enter a valid email address.")
        }
        return value
    }

    static func registration(
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        password: String,
        confirmPassword: String
    ) throws -> (firstName: String, lastName: String, email: String, phone: String) {
        let profile = try profile(firstName: firstName, lastName: lastName, email: email, phone: phone)
        try validatePassword(password)
        guard password == confirmPassword else {
            throw LocalAuthError.invalidInput("Passwords do not match.")
        }

        return profile
    }

    static func profile(
        firstName: String,
        lastName: String,
        email: String,
        phone: String
    ) throws -> (firstName: String, lastName: String, email: String, phone: String) {
        let firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !firstName.isEmpty, !lastName.isEmpty else {
            throw LocalAuthError.invalidInput("Enter your first and last name.")
        }
        guard phone.filter(\.isNumber).count >= 7 else {
            throw LocalAuthError.invalidInput("Enter a valid phone number.")
        }

        return (firstName, lastName, try normalizedEmail(email), phone)
    }

    static func login(email: String, password: String) throws -> String {
        guard !password.isEmpty else {
            throw LocalAuthError.invalidInput("Enter your password.")
        }
        return try normalizedEmail(email)
    }

    private static func validatePassword(_ password: String) throws {
        guard password.count >= 6 else {
            throw LocalAuthError.invalidInput("Password must be at least 6 characters.")
        }
    }
}



enum AppRole: String, CaseIterable, Identifiable {
    case passenger
    case driver

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }

    var icon: String {
        self == .driver ? "car.fill" : "person.fill"
    }
}
