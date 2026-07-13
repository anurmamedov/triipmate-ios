import Foundation

enum AppEnvironmentMode: String {
    case local
    case staging
}

struct FirebaseBackendConfig {
    let mode: AppEnvironmentMode
    let projectId: String
    let apiKey: String
    let storageBucket: String?
    let authBaseURL: URL
    let tokenURL: URL
    let firestoreDocumentsURL: URL
    let isStorageEnabled: Bool
    let configurationError: String?

    static var current: FirebaseBackendConfig {
        let rawValue = ProcessInfo.processInfo.environment["TRIIPMATE_ENVIRONMENT"] ?? AppEnvironmentMode.local.rawValue
        let mode = AppEnvironmentMode(rawValue: rawValue.lowercased()) ?? .local

        switch mode {
        case .local:
            return local
        case .staging:
            return staging
        }
    }

    func validate() throws {
        if let configurationError {
            throw LocalAuthError.invalidInput(configurationError)
        }
    }

    private static var local: FirebaseBackendConfig {
        let projectId = "demo-triipmate-local"
        return FirebaseBackendConfig(
            mode: .local,
            projectId: projectId,
            apiKey: "triipmate-local",
            storageBucket: "\(projectId).appspot.com",
            authBaseURL: URL(string: "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1")!,
            tokenURL: URL(string: "http://127.0.0.1:9099/securetoken.googleapis.com/v1/token")!,
            firestoreDocumentsURL: URL(string: "http://127.0.0.1:8080/v1/projects/\(projectId)/databases/(default)/documents")!,
            isStorageEnabled: true,
            configurationError: nil
        )
    }

    private static var staging: FirebaseBackendConfig {
        let environment = ProcessInfo.processInfo.environment
        if let projectId = environment["TRIIPMATE_FIREBASE_PROJECT_ID"], !projectId.isEmpty,
           let apiKey = environment["TRIIPMATE_FIREBASE_API_KEY"], !apiKey.isEmpty {
            return FirebaseBackendConfig(
                mode: .staging,
                projectId: projectId,
                apiKey: apiKey,
                storageBucket: environment["TRIIPMATE_FIREBASE_STORAGE_BUCKET"],
                authBaseURL: URL(string: "https://identitytoolkit.googleapis.com/v1")!,
                tokenURL: URL(string: "https://securetoken.googleapis.com/v1/token")!,
                firestoreDocumentsURL: URL(string: "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents")!,
                isStorageEnabled: false,
                configurationError: nil
            )
        }

        guard let plistURL = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let plistData = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
              let projectId = plist["PROJECT_ID"] as? String,
              let apiKey = plist["API_KEY"] as? String else {
            return stagingFromDefaults
        }

        return FirebaseBackendConfig(
            mode: .staging,
            projectId: projectId,
            apiKey: apiKey,
            storageBucket: plist["STORAGE_BUCKET"] as? String,
            authBaseURL: URL(string: "https://identitytoolkit.googleapis.com/v1")!,
            tokenURL: URL(string: "https://securetoken.googleapis.com/v1/token")!,
            firestoreDocumentsURL: URL(string: "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents")!,
            isStorageEnabled: false,
            configurationError: nil
        )
    }

    private static var stagingFromDefaults: FirebaseBackendConfig {
        let projectId = "triipmate-staging"
        return FirebaseBackendConfig(
            mode: .staging,
            projectId: projectId,
            apiKey: "AIzaSyBoN_5hEN73cwJvLiWrmf98EPFyMzZEMWY",
            storageBucket: nil,
            authBaseURL: URL(string: "https://identitytoolkit.googleapis.com/v1")!,
            tokenURL: URL(string: "https://securetoken.googleapis.com/v1/token")!,
            firestoreDocumentsURL: URL(string: "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents")!,
            isStorageEnabled: false,
            configurationError: nil
        )
    }

    private static func stagingWithError(_ message: String) -> FirebaseBackendConfig {
        FirebaseBackendConfig(
            mode: .staging,
            projectId: "",
            apiKey: "",
            storageBucket: nil,
            authBaseURL: URL(string: "https://identitytoolkit.googleapis.com/v1")!,
            tokenURL: URL(string: "https://securetoken.googleapis.com/v1/token")!,
            firestoreDocumentsURL: URL(string: "https://firestore.googleapis.com/v1/projects/missing/databases/(default)/documents")!,
            isStorageEnabled: false,
            configurationError: message
        )
    }
}
