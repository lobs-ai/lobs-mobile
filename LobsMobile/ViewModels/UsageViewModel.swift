import Foundation
import SwiftUI

enum TimeWindow: String, CaseIterable, Identifiable {
    case day = "day"
    case week = "week"
    case month = "month"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        }
    }

    var apiValue: String { rawValue }
}

@MainActor
class UsageViewModel: ObservableObject {
    @Published var timeWindow: TimeWindow = .day
    @Published var summary: UsageSummaryResponse?
    @Published var projection: UsageProjectionResponse?
    @Published var workerHistory: [WorkerHistoryRun] = []
    @Published var isLoading = false
    @Published var error: String?

    private var apiService: APIService?

    func setAPIService(_ api: APIService?) {
        self.apiService = api
    }

    func loadData() async {
        guard let api = apiService else {
            error = "Not connected to server"
            return
        }

        isLoading = true
        error = nil

        do {
            async let summaryTask = api.loadUsageDashboard(window: timeWindow.apiValue)
            async let projectionTask = api.loadUsageProjection()
            async let historyTask = api.loadWorkerHistory()

            let (summaryResult, projectionResult, historyResult) = try await (
                summaryTask,
                projectionTask,
                historyTask
            )

            self.summary = summaryResult
            self.projection = projectionResult
            self.workerHistory = historyResult.runs
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Computed Helpers

    var totalTokens: Int {
        guard let s = summary else { return 0 }
        return s.totalInputTokens + s.totalOutputTokens
    }

    var successRate: Double {
        guard let s = summary, s.totalRequests > 0 else { return 0 }
        let failed = s.byProvider.reduce(0) { $0 + Int(Double($1.requests) * $1.errorRate) }
        let successful = s.totalRequests - failed
        return Double(successful) / Double(s.totalRequests)
    }

    var costTrendData: [DailyCostPoint] {
        summary?.dailySeries ?? []
    }
}
