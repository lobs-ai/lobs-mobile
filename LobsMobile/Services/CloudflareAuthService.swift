import Foundation
import AuthenticationServices

/// Handles Cloudflare Access authentication for the lobs-mobile app.
/// Mirrors the flow from lobs-vim: get a CF_Authorization JWT, attach it as a cookie on all requests.
///
/// Flow:
/// 1. Open ASWebAuthenticationSession to the server URL (Cloudflare Access login page)
/// 2. User authenticates via Cloudflare's identity provider
/// 3. Extract CF_Authorization cookie from the response
/// 4. Cache token in Keychain
/// 5. APIService attaches Cookie: CF_Authorization=<token> on all requests
@MainActor
class CloudflareAuthService: NSObject, ObservableObject {
    @Published var cfToken: String?
    @Published var isAuthenticating = false
    @Published var error: String?
    
    private let keychainKey = "com.lobs.mobile.cf-authorization"
    
    override init() {
        super.init()
        // Load cached token from Keychain on init
        self.cfToken = loadTokenFromKeychain()
    }
    
    /// Whether the server URL looks like it's behind Cloudflare Access
    static func needsCloudflareAuth(serverURL: String) -> Bool {
        // Match *.lobslab.com URLs — same heuristic as lobs-vim
        return serverURL.contains(".lobslab.com")
    }
    
    var isAuthenticated: Bool {
        cfToken != nil
    }
    
    /// Initiate Cloudflare Access login via in-app browser sheet
    func login(serverURL: String) {
        guard let url = URL(string: serverURL) else {
            error = "Invalid server URL"
            return
        }
        
        isAuthenticating = true
        error = nil
        
        // Cloudflare Access intercepts the first request to a protected URL.
        // We use the /cdn-cgi/access/login endpoint which is Cloudflare's standard login path.
        let loginURL = url.appendingPathComponent("cdn-cgi/access/login")
        
        // The callback URL scheme for our app
        let scheme = "lobsmobile"
        
        let session = ASWebAuthenticationSession(
            url: loginURL,
            callbackURLScheme: scheme
        ) { [weak self] callbackURL, authError in
            Task { @MainActor in
                guard let self = self else { return }
                self.isAuthenticating = false
                
                if let authError = authError {
                    // User cancelled is not a real error
                    if (authError as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                        return
                    }
                    self.error = authError.localizedDescription
                    return
                }
                
                // After successful auth, the CF_Authorization cookie should be set.
                // Try to extract it from shared cookie storage.
                self.extractCFToken(for: url)
            }
        }
        
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false // Keep cookies!
        session.start()
    }
    
    /// Alternative login: directly open the server URL and grab the cookie after redirect.
    /// This works because ASWebAuthenticationSession shares cookies when prefersEphemeral is false.
    func loginDirect(serverURL: String) {
        guard let url = URL(string: serverURL) else {
            error = "Invalid server URL"
            return
        }
        
        isAuthenticating = true
        error = nil
        
        // Just hit the server root — Cloudflare Access will redirect to login
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: nil // No callback — we just need the cookies
        ) { [weak self] _, authError in
            Task { @MainActor in
                guard let self = self else { return }
                self.isAuthenticating = false
                
                if let authError = authError {
                    if (authError as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                        // User dismissed — check if we got the cookie anyway
                        // (Cloudflare sets it before the final redirect sometimes)
                        self.extractCFToken(for: url)
                        return
                    }
                    self.error = authError.localizedDescription
                    return
                }
                
                self.extractCFToken(for: url)
            }
        }
        
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }
    
    /// Extract CF_Authorization from HTTPCookieStorage
    private func extractCFToken(for url: URL) {
        let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
        
        if let cfCookie = cookies.first(where: { $0.name == "CF_Authorization" }) {
            self.cfToken = cfCookie.value
            saveTokenToKeychain(cfCookie.value)
            self.error = nil
        } else {
            // Also check parent domain cookies
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.path = "/"
            if let rootURL = components?.url {
                let rootCookies = HTTPCookieStorage.shared.cookies(for: rootURL) ?? []
                if let cfCookie = rootCookies.first(where: { $0.name == "CF_Authorization" }) {
                    self.cfToken = cfCookie.value
                    saveTokenToKeychain(cfCookie.value)
                    self.error = nil
                    return
                }
            }
            
            self.error = "Authentication completed but CF_Authorization cookie not found. Try again."
        }
    }
    
    /// Clear the cached token (logout)
    func logout() {
        cfToken = nil
        deleteTokenFromKeychain()
    }
    
    // MARK: - Keychain Storage
    
    private func saveTokenToKeychain(_ token: String) {
        let data = Data(token.utf8)
        
        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
    
    private func loadTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    private func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension CloudflareAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the key window for the auth sheet to present from
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
