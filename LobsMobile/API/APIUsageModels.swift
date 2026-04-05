import Foundation

struct UsageProviderSummary: Codable, Identifiable {
  var provider: String
  var requests: Int
  var inputTokens: Int
  var outputTokens: Int
  var cachedTokens: Int
  var estimatedCostUsd: Double
  var avgLatencyMs: Double?
  var errorRate: Double

  var id: String { provider }
}

struct UsageModelSummary: Codable, Identifiable {
  var provider: String
  var model: String
  var routeType: String
  var requests: Int
  var inputTokens: Int
  var outputTokens: Int
  var cachedTokens: Int
  var estimatedCostUsd: Double
  var avgLatencyMs: Double?
  var errorRate: Double

  var id: String { "\(provider)::\(model)::\(routeType)" }
}

struct DailyCostPoint: Codable, Identifiable {
  var date: Date
  var costUsd: Double
  var provider: String?

  var id: Date { date }
}

struct UsageSummaryResponse: Codable {
  var window: String
  var periodStart: Date
  var periodEnd: Date
  var totalRequests: Int
  var totalInputTokens: Int
  var totalOutputTokens: Int
  var totalCachedTokens: Int
  var totalEstimatedCostUsd: Double
  var byProvider: [UsageProviderSummary]
  var byModel: [UsageModelSummary]
  var dailySeries: [DailyCostPoint]?
}

struct UsageProjectionResponse: Codable {
  var monthStart: Date
  var now: Date
  var monthToDateCostUsd: Double
  var currentDailyBurnUsd: Double
  var projectedMonthEndCostUsd: Double
}

struct UsageBudgetLimits: Codable {
  var monthlyTotalUsd: Double
  var dailyAlertUsd: Double
  var perProviderMonthlyUsd: [String: Double]
  var perTaskHardCapUsd: Double
}

struct UsageRoutingPolicy: Codable {
  var subscriptionFirstTaskTypes: [String]
  var subscriptionProviders: [String]
  var subscriptionModels: [String]
  var fallbackChains: [String: [String]]
  var qualityPreference: [String]
}
