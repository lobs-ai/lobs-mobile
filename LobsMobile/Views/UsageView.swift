import SwiftUI
import Charts

struct UsageView: View {
    @StateObject private var viewModel = UsageViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Time window picker
                    Picker("Window", selection: $viewModel.timeWindow) {
                        ForEach(TimeWindow.allCases) { window in
                            Text(window.displayName).tag(window)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: viewModel.timeWindow) {
                        Task { await viewModel.loadData() }
                    }
                    
                    if viewModel.isLoading && viewModel.summary == nil {
                        ProgressView("Loading usage data...")
                            .padding(.top, 40)
                    } else if let error = viewModel.error, viewModel.summary == nil {
                        errorView(error)
                    } else if let summary = viewModel.summary {
                        summaryCards(summary)
                        costTrendChart
                        providerBreakdown(summary.byProvider)
                        modelBreakdown(summary.byModel)
                        projectionCard
                        workerHistorySection
                    }
                }
                .padding(.bottom, 20)
            }
            .nexusBackground()
            .navigationTitle("Usage & Stats")
            .refreshable {
                await viewModel.loadData()
            }
            .task {
                viewModel.setAPIService(appState.apiService)
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Summary Cards
    
    private func summaryCards(_ summary: UsageSummaryResponse) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            StatCard(
                title: "Total Cost",
                value: formatCost(summary.totalEstimatedCostUsd),
                icon: "dollarsign.circle.fill",
                color: .nexusSuccess
            )
            StatCard(
                title: "Tokens",
                value: formatTokens(viewModel.totalTokens),
                icon: "text.word.spacing",
                color: .nexusBlue
            )
            StatCard(
                title: "Requests",
                value: formatCount(summary.totalRequests),
                icon: "arrow.up.arrow.down.circle.fill",
                color: Color(red: 168/255, green: 85/255, blue: 247/255)
            )
            StatCard(
                title: "Success Rate",
                value: formatPercent(viewModel.successRate),
                icon: "checkmark.circle.fill",
                color: viewModel.successRate > 0.95 ? .nexusSuccess : (viewModel.successRate > 0.8 ? .nexusWarning : .nexusError)
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Cost Trend Chart
    
    @ViewBuilder
    private var costTrendChart: some View {
        if !viewModel.costTrendData.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Cost Trend")
                    .font(.headline)
                    .foregroundColor(.nexusText)
                    .padding(.horizontal)
                
                Chart(viewModel.costTrendData) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Cost", point.costUsd)
                    )
                    .foregroundStyle(.nexusBlue.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let cost = value.as(Double.self) {
                                Text(formatCost(cost))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Provider Breakdown
    
    private func providerBreakdown(_ providers: [UsageProviderSummary]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("By Provider")
                .font(.headline)
                .foregroundColor(.nexusText)
                .padding(.horizontal)
            
            ForEach(providers) { provider in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(provider.provider)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("\(formatCount(provider.requests)) requests · \(formatTokens(provider.inputTokens + provider.outputTokens)) tokens")
                            .font(.caption)
                            .foregroundColor(.nexusMuted)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCost(provider.estimatedCostUsd))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if provider.errorRate > 0 {
                            Text("\(formatPercent(provider.errorRate)) errors")
                                .font(.caption)
                                .foregroundColor(.nexusError)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Model Breakdown
    
    private func modelBreakdown(_ models: [UsageModelSummary]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("By Model")
                .font(.headline)
                .foregroundColor(.nexusText)
                .padding(.horizontal)
            
            ForEach(models.sorted(by: { $0.estimatedCostUsd > $1.estimatedCostUsd }).prefix(10)) { model in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.model)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Text("\(model.provider) · \(model.routeType)")
                            .font(.caption)
                            .foregroundColor(.nexusMuted)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCost(model.estimatedCostUsd))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(formatTokens(model.inputTokens + model.outputTokens))
                            .font(.caption)
                            .foregroundColor(.nexusMuted)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Projection Card
    
    @ViewBuilder
    private var projectionCard: some View {
        if let projection = viewModel.projection {
            VStack(alignment: .leading, spacing: 8) {
                Text("Monthly Projection")
                    .font(.headline)
                    .foregroundColor(.nexusText)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    HStack {
                        Label("Month to Date", systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundColor(.nexusMuted)
                        Spacer()
                        Text(formatCost(projection.monthToDateCostUsd))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                        .background(Color.nexusBorder)
                    
                    HStack {
                        Label("Daily Burn", systemImage: "flame")
                            .font(.subheadline)
                            .foregroundColor(.nexusMuted)
                        Spacer()
                        Text("\(formatCost(projection.currentDailyBurnUsd))/day")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                        .background(Color.nexusBorder)
                    
                    HStack {
                        Label("Projected End", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.subheadline)
                            .foregroundColor(.nexusMuted)
                        Spacer()
                        Text(formatCost(projection.projectedMonthEndCostUsd))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(projection.projectedMonthEndCostUsd > 50 ? .nexusError : .nexusText)
                    }
                }
                .padding()
                .background(Color.nexusSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.nexusBorder, lineWidth: 1)
                )
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Worker History
    
    private var workerHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Workers")
                .font(.headline)
                .foregroundColor(.nexusText)
                .padding(.horizontal)
            
            if viewModel.workerHistory.isEmpty {
                Text("No recent worker runs")
                    .font(.subheadline)
                    .foregroundColor(.nexusMuted)
                    .padding(.horizontal)
            } else {
                ForEach(viewModel.workerHistory.prefix(20)) { run in
                    WorkerRunRow(run: run)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.nexusWarning)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.nexusMuted)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.loadData() }
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.nexusNavy)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.nexusTeal)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.top, 40)
        .padding(.horizontal)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundColor(.nexusMuted)
        }
        .padding(12)
        .background(Color.nexusSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.nexusBorder, lineWidth: 1)
        )
    }
}

// MARK: - Worker Run Row

struct WorkerRunRow: View {
    let run: WorkerHistoryRun
    
    var body: some View {
        HStack(spacing: 10) {
            // Agent type icon
            Image(systemName: agentIcon)
                .foregroundColor((run.succeeded ?? false) ? .nexusSuccess : .nexusError)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(run.model ?? "Unknown model")
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(run.agentType)
                        .font(.caption)
                        .foregroundColor(.nexusMuted)
                    
                    if let duration = runDuration {
                        Text("·")
                            .foregroundColor(.nexusMuted.opacity(0.6))
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.nexusMuted)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if let cost = run.totalCostUSD {
                    Text(formatCost(cost))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Image(systemName: (run.succeeded ?? false) ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor((run.succeeded ?? false) ? .nexusSuccess : .nexusError)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private var agentIcon: String {
        switch run.agentType {
        case "programmer": return "chevron.left.forwardslash.chevron.right"
        case "writer": return "pencil"
        case "researcher": return "magnifyingglass"
        case "reviewer": return "eye"
        case "architect": return "building.2"
        default: return "cpu"
        }
    }
    
    private var runDuration: Double? {
        guard let start = run.startedAt, let end = run.endedAt else { return nil }
        return end.timeIntervalSince(start)
    }
}
