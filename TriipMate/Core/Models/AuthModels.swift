import Foundation

struct AuthUser {
    let uid: String
    let email: String
    let idToken: String
}

struct UserProfile {
    let uid: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let role: AppRole
    let profilePhotoPath: String?
}

struct SavedVehicle: Identifiable, Hashable {
    let id: String
    let make: String
    let model: String
    let year: String
    let powerType: String
    let bodyType: String

    var displayName: String {
        "\(year) \(make) \(model)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum LocalAuthError: LocalizedError {
    case invalidResponse
    case server(String)
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The auth emulator returned an unexpected response."
        case .server(let message):
            return message
        case .profileNotFound:
            return "We could not find your local profile data."
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

