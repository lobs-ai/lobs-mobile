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
        connectionStatus = .unknown
    }
}
