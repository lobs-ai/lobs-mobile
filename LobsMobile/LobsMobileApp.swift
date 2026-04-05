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
    @Published var cloudflareAuth = CloudflareAuthService()
    
    /// Whether the current server URL requires Cloudflare Access auth
    var needsCloudflareAuth: Bool {
        CloudflareAuthService.needsCloudflareAuth(serverURL: serverURL)
    }
    
    init() {
        // Load from UserDefaults
        self.serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? "https://nexus.lobslab.com"
        self.apiToken = UserDefaults.standard.string(forKey: "apiToken") ?? ""
        
        // Initialize API service
        if let service = try? APIService(baseURLString: serverURL, apiToken: apiToken) {
            self.apiService = service
        }
        
        // Sync CF token to API service
        syncCFToken()
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
    
    /// Sync the CF token from CloudflareAuthService to the APIService
    func syncCFToken() {
        apiService?.cfToken = cloudflareAuth.cfToken
    }
    
    private func updateAPIService() {
        if let service = try? APIService(baseURLString: serverURL, apiToken: apiToken) {
            service.cfToken = cloudflareAuth.cfToken
            self.apiService = service
        }
    }
}
