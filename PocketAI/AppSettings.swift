import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject {
    @Published var demoMode: Bool {
        didSet { UserDefaults.standard.set(demoMode, forKey: "demoMode") }
    }
    @Published var backendURL: String {
        didSet { UserDefaults.standard.set(backendURL, forKey: "backendURL") }
    }

    init() {
        self.demoMode = UserDefaults.standard.object(forKey: "demoMode") as? Bool ?? true
        self.backendURL = UserDefaults.standard.string(forKey: "backendURL") ?? "http://localhost:3000"
    }
}
