import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var serverURL: String = ""
    @State private var apiToken: String = ""
    @State private var isTestingConnection = false
    @State private var connectionStatus: ConnectionStatus = .unknown
    
    enum ConnectionStatus {
        case unknown
        case success
        case failure(String)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Server Configuration") {
                    TextField("Server URL", text: $serverURL)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    
                    SecureField("API Token", text: $apiToken)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                }
                
                Section {
                    Button {
                        Task {
                            await testConnection()
                        }
                    } label: {
                        HStack {
                            Text("Test Connection")
                            Spacer()
                            if isTestingConnection {
                                ProgressView()
                            } else {
                                connectionStatusIcon
                            }
                        }
                    }
                    .disabled(isTestingConnection)
                } footer: {
                    connectionStatusText
                }
                
                // Cloudflare Access section — only shown for *.lobslab.com servers
                if appState.needsCloudflareAuth {
                    Section {
                        HStack {
                            Text("Status")
                            Spacer()
                            if appState.cloudflareAuth.isAuthenticated {
                                Label("Authenticated", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.subheadline)
                            } else {
                                Label("Not Authenticated", systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.subheadline)
                            }
                        }
                        
                        if appState.cloudflareAuth.isAuthenticated {
                            Button(role: .destructive) {
                                appState.cloudflareAuth.logout()
                                appState.syncCFToken()
                            } label: {
                                Label("Sign Out of Cloudflare", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } else {
                            Button {
                                appState.cloudflareAuth.loginDirect(serverURL: serverURL)
                            } label: {
                                HStack {
                                    Label("Sign In with Cloudflare", systemImage: "lock.shield")
                                    Spacer()
                                    if appState.cloudflareAuth.isAuthenticating {
                                        ProgressView()
                                    }
                                }
                            }
                            .disabled(appState.cloudflareAuth.isAuthenticating || serverURL.isEmpty)
                        }
                    } header: {
                        Text("Cloudflare Access")
                    } footer: {
                        if let error = appState.cloudflareAuth.error {
                            Text(error)
                                .foregroundStyle(.red)
                        } else {
                            Text("Required for servers behind Cloudflare Access. Opens a browser for authentication.")
                        }
                    }
                }
                
                Section("Actions") {
                    Button("Save Settings") {
                        saveSettings()
                    }
                    .disabled(serverURL.isEmpty || apiToken.isEmpty)
                }
                
                Section("About") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                serverURL = appState.serverURL
                apiToken = appState.apiToken
            }
            .onChange(of: appState.cloudflareAuth.cfToken) {
                appState.syncCFToken()
            }
        }
    }
    
    @ViewBuilder
    private var connectionStatusIcon: some View {
        switch connectionStatus {
        case .unknown:
            EmptyView()
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failure:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        }
    }
    
    @ViewBuilder
    private var connectionStatusText: some View {
        switch connectionStatus {
        case .unknown:
            EmptyView()
        case .success:
            Text("Connection successful!")
                .foregroundColor(.green)
        case .failure(let message):
            Text("Connection failed: \(message)")
                .foregroundColor(.red)
        }
    }
    
    private func testConnection() async {
        isTestingConnection = true
        defer { isTestingConnection = false }
        
        do {
            let testService = try APIService(baseURLString: serverURL, apiToken: apiToken)
            let success = try await testService.testConnection()
            connectionStatus = success ? .success : .failure("Unknown error")
        } catch {
            connectionStatus = .failure(error.localizedDescription)
        }
    }
    
    private func saveSettings() {
        appState.updateServerURL(serverURL)
        appState.updateAPIToken(apiToken)
        appState.syncCFToken()
        connectionStatus = .unknown
    }
}
