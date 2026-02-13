import SwiftUI

@main
struct LobsMobileApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var serverURL: String
    @Published var apiToken: String
    @Published var apiService: APIService?
    
    init() {
        // Load from UserDefaults
        self.serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? "http://localhost:8000"
        self.apiToken = UserDefaults.standard.string(forKey: "apiToken") ?? "z5mr-WWjPxAAHvRd2ZULm7HLNW1oRubXmcMiBJoEmsU"
        
        // Initialize API service
        if let service = try? APIService(baseURLString: serverURL, apiToken: apiToken) {
            self.apiService = service
        }
    }
    
    func updateServerURL(_ url: String) {
        self.serverURL = url
        UserDefaults.standard.set(url, forKey: "serverURL")
        updateAPIService()
    }
    
    func updateAPIToken(_ token: String) {
        self.apiToken = token
        UserDefaults.standard.set(token, forKey: "apiToken")
        updateAPIService()
    }
    
    private func updateAPIService() {
        if let service = try? APIService(baseURLString: serverURL, apiToken: apiToken) {
            self.apiService = service
        }
    }
}
