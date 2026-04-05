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
            ScrollView {
                VStack(spacing: 16) {
                    // Server Configuration
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Server Configuration", systemImage: "server.rack")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.nexusTeal)
                        
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Server URL")
                                    .font(.caption)
                                    .foregroundColor(.nexusMuted)
                                TextField("https://nexus.lobslab.com", text: $serverURL)
                                    .autocapitalization(.none)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.URL)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.nexusSurface2)
                                    .foregroundColor(.nexusText)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.nexusBorder, lineWidth: 1)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("API Token")
                                    .font(.caption)
                                    .foregroundColor(.nexusMuted)
                                SecureField("Enter API token", text: $apiToken)
                                    .autocapitalization(.none)
                                    .textInputAutocapitalization(.never)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.nexusSurface2)
                                    .foregroundColor(.nexusText)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.nexusBorder, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .nexusCard()
                    
                    // Connection Test
                    VStack(spacing: 12) {
                        Button {
                            Task { await testConnection() }
                        } label: {
                            HStack {
                                Text("Test Connection")
                                    .fontWeight(.medium)
                                Spacer()
                                if isTestingConnection {
                                    ProgressView()
                                        .tint(.nexusTeal)
                                        .scaleEffect(0.8)
                                } else {
                                    connectionStatusIcon
                                }
                            }
                            .foregroundColor(.nexusText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.nexusSurface2)
                            .cornerRadius(8)
                        }
                        .disabled(isTestingConnection)
                        
                        connectionStatusText
                    }
                    .nexusCard()
                    
                    // Cloudflare Access
                    if appState.needsCloudflareAuth {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Cloudflare Access", systemImage: "lock.shield.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.nexusTeal)
                            
                            HStack {
                                Text("Status")
                                    .foregroundColor(.nexusMuted)
                                Spacer()
                                if appState.cloudflareAuth.isAuthenticated {
                                    Label("Authenticated", systemImage: "checkmark.circle.fill")
                                        .foregroundColor(.nexusSuccess)
                                        .font(.subheadline)
                                } else {
                                    Label("Not Authenticated", systemImage: "xmark.circle.fill")
                                        .foregroundColor(.nexusError)
                                        .font(.subheadline)
                                }
                            }
                            
                            if appState.cloudflareAuth.isAuthenticated {
                                Button {
                                    appState.cloudflareAuth.logout()
                                    appState.syncCFToken()
                                } label: {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text("Sign Out")
                                    }
                                    .foregroundColor(.nexusError)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.nexusError.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            } else {
                                Button {
                                    appState.cloudflareAuth.loginDirect(serverURL: serverURL)
                                } label: {
                                    HStack {
                                        Image(systemName: "lock.shield")
                                        Text("Sign In with Cloudflare")
                                        Spacer()
                                        if appState.cloudflareAuth.isAuthenticating {
                                            ProgressView()
                                                .tint(.nexusTeal)
                                                .scaleEffect(0.8)
                                        }
                                    }
                                    .foregroundColor(.nexusTeal)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.nexusTeal.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .disabled(appState.cloudflareAuth.isAuthenticating || serverURL.isEmpty)
                            }
                            
                            if let error = appState.cloudflareAuth.error {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.nexusError)
                            } else {
                                Text("Required for servers behind Cloudflare Access.")
                                    .font(.caption)
                                    .foregroundColor(.nexusMuted)
                            }
                        }
                        .nexusCard()
                    }
                    
                    // Save Button
                    Button {
                        saveSettings()
                    } label: {
                        Text("Save Settings")
                            .fontWeight(.semibold)
                            .foregroundColor(.nexusNavy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.nexusTeal)
                            .cornerRadius(10)
                    }
                    .disabled(serverURL.isEmpty)
                    .opacity(serverURL.isEmpty ? 0.5 : 1)
                    
                    // About
                    VStack(alignment: .leading, spacing: 12) {
                        Label("About", systemImage: "info.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.nexusTeal)
                        
                        HStack {
                            Text("Version")
                                .foregroundColor(.nexusMuted)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.nexusText)
                        }
                        
                        HStack {
                            Text("Build")
                                .foregroundColor(.nexusMuted)
                            Spacer()
                            Text("1")
                                .foregroundColor(.nexusText)
                        }
                    }
                    .nexusCard()
                }
                .padding(16)
            }
            .nexusBackground()
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
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.nexusMuted)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.nexusSuccess)
        case .failure:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.nexusError)
        }
    }
    
    @ViewBuilder
    private var connectionStatusText: some View {
        switch connectionStatus {
        case .unknown:
            EmptyView()
        case .success:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                Text("Connected successfully")
            }
            .foregroundColor(.nexusSuccess)
            .font(.caption)
        case .failure(let message):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                Text(message)
            }
            .foregroundColor(.nexusError)
            .font(.caption)
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
