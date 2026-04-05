import Foundation

// MARK: - Cost Formatting

func formatCost(_ value: Double) -> String {
    if value < 0.01 {
        return String(format: "$%.4f", value)
    } else if value < 1.0 {
        return String(format: "$%.3f", value)
    } else {
        return String(format: "$%.2f", value)
    }
}

// MARK: - Token Formatting

func formatTokens(_ value: Int) -> String {
    if value >= 1_000_000 {
        return String(format: "%.1fM", Double(value) / 1_000_000)
    } else if value >= 1_000 {
        return String(format: "%.0fK", Double(value) / 1_000)
    } else {
        return "\(value)"
    }
}

func formatTokens(_ value: Int?) -> String {
    guard let value = value else { return "—" }
    return formatTokens(value)
}

// MARK: - Duration Formatting

func formatDuration(_ seconds: Double) -> String {
    if seconds < 60 {
        return String(format: "%.0fs", seconds)
    } else if seconds < 3600 {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return secs > 0 ? "\(minutes)m \(secs)s" : "\(minutes)m"
    } else {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    }
}

// MARK: - Percentage Formatting

func formatPercent(_ value: Double) -> String {
    return String(format: "%.1f%%", value * 100)
}

func formatPercent(_ value: Double?) -> String {
    guard let value = value else { return "—" }
    return formatPercent(value)
}

// MARK: - Count Formatting

func formatCount(_ value: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}
