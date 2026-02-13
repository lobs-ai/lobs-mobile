import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var overview: SystemOverview?
    @Published var isLoading = false
    @Published var error: String?
    
    func load(apiService: APIService?) async {
        guard let api = apiService else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            overview = try await api.fetchSystemOverview()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
