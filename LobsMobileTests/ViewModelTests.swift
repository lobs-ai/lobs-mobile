import XCTest
@testable import LobsMobile

// MARK: - ViewModelTests
//
// Comprehensive unit tests for all ViewModels and Helpers in LobsMobile.
// All ViewModels are @MainActor, so the test class is also @MainActor.

@MainActor
final class ViewModelTests: XCTestCase {

    // MARK: - Shared test fixtures

    private let now = Date()

    private func makeTask(
        id: String = "task-1",
        title: String = "Test Task",
        status: TaskStatus = .active,
        owner: TaskOwner = .lobs,
        sortOrder: Int? = nil,
        projectId: String? = nil
    ) -> DashboardTask {
        DashboardTask(
            id: id,
            title: title,
            status: status,
            owner: owner,
            createdAt: now,
            updatedAt: now,
            projectId: projectId,
            sortOrder: sortOrder
        )
    }

    private func makeProject(
        id: String = "proj-1",
        title: String = "Test Project",
        archived: Bool? = false,
        type: ProjectType? = .kanban,
        sortOrder: Int? = nil
    ) -> Project {
        Project(
            id: id,
            title: title,
            createdAt: now,
            updatedAt: now,
            archived: archived,
            type: type,
            sortOrder: sortOrder
        )
    }

    private func makeUsageSummary(
        totalRequests: Int = 100,
        totalInputTokens: Int = 1000,
        totalOutputTokens: Int = 500,
        byProvider: [UsageProviderSummary] = [],
        dailySeries: [DailyCostPoint]? = nil
    ) -> UsageSummaryResponse {
        UsageSummaryResponse(
            window: "day",
            periodStart: now,
            periodEnd: now,
            totalRequests: totalRequests,
            totalInputTokens: totalInputTokens,
            totalOutputTokens: totalOutputTokens,
            totalCachedTokens: 0,
            totalEstimatedCostUsd: 1.23,
            byProvider: byProvider,
            byModel: [],
            dailySeries: dailySeries
        )
    }

    private func makeProviderSummary(
        provider: String = "anthropic",
        requests: Int = 100,
        errorRate: Double = 0.0
    ) -> UsageProviderSummary {
        UsageProviderSummary(
            provider: provider,
            requests: requests,
            inputTokens: 500,
            outputTokens: 250,
            cachedTokens: 0,
            estimatedCostUsd: 0.50,
            avgLatencyMs: nil,
            errorRate: errorRate
        )
    }

    // =========================================================================
    // MARK: - Formatter Tests
    // =========================================================================

    // MARK: formatCost

    func testFormatCost_verySmall() {
        XCTAssertEqual(formatCost(0.001), "$0.0010")
    }

    func testFormatCost_verySmall_exactBoundaryBelow() {
        // 0.009 is < 0.01 → 4 decimal places
        XCTAssertEqual(formatCost(0.009), "$0.0090")
    }

    func testFormatCost_small() {
        // 0.05 is >= 0.01 but < 1.0 → 3 decimal places
        XCTAssertEqual(formatCost(0.05), "$0.050")
    }

    func testFormatCost_smallAtLowerBound() {
        // 0.01 is >= 0.01 → 3 decimal places
        XCTAssertEqual(formatCost(0.01), "$0.010")
    }

    func testFormatCost_normal() {
        XCTAssertEqual(formatCost(5.50), "$5.50")
    }

    func testFormatCost_zero() {
        // 0.0 < 0.01 → 4 decimal places
        XCTAssertEqual(formatCost(0.0), "$0.0000")
    }

    func testFormatCost_large() {
        XCTAssertEqual(formatCost(123.456), "$123.46")
    }

    func testFormatCost_exactOne() {
        // 1.0 >= 1.0 → 2 decimal places
        XCTAssertEqual(formatCost(1.0), "$1.00")
    }

    func testFormatCost_belowOne() {
        // 0.999 is < 1.0 → 3 decimal places
        XCTAssertEqual(formatCost(0.999), "$0.999")
    }

    func testFormatCost_negative() {
        // negative values are < 0.01, treated as very small
        XCTAssertEqual(formatCost(-0.005), "$-0.0050")
    }

    // MARK: formatTokens (Int)

    func testFormatTokens_small() {
        XCTAssertEqual(formatTokens(500), "500")
    }

    func testFormatTokens_zero() {
        XCTAssertEqual(formatTokens(0), "0")
    }

    func testFormatTokens_justBelowThousand() {
        XCTAssertEqual(formatTokens(999), "999")
    }

    func testFormatTokens_exactThousand() {
        XCTAssertEqual(formatTokens(1000), "1K")
    }

    func testFormatTokens_thousands() {
        XCTAssertEqual(formatTokens(5000), "5K")
    }

    func testFormatTokens_thousands_rounded() {
        // 1500 → "2K" (%.0f rounds)
        XCTAssertEqual(formatTokens(1500), "2K")
    }

    func testFormatTokens_justBelowMillion() {
        XCTAssertEqual(formatTokens(999_999), "1000K")
    }

    func testFormatTokens_exactMillion() {
        XCTAssertEqual(formatTokens(1_000_000), "1.0M")
    }

    func testFormatTokens_millions() {
        XCTAssertEqual(formatTokens(1_500_000), "1.5M")
    }

    func testFormatTokens_largeMillion() {
        XCTAssertEqual(formatTokens(10_000_000), "10.0M")
    }

    // MARK: formatTokens (Int?)

    func testFormatTokens_nil() {
        let value: Int? = nil
        XCTAssertEqual(formatTokens(value), "—")
    }

    func testFormatTokens_optionalWithValue() {
        let value: Int? = 2000
        XCTAssertEqual(formatTokens(value), "2K")
    }

    func testFormatTokens_optionalZero() {
        let value: Int? = 0
        XCTAssertEqual(formatTokens(value), "0")
    }

    // MARK: formatDuration

    func testFormatDuration_seconds() {
        XCTAssertEqual(formatDuration(45.0), "45s")
    }

    func testFormatDuration_zeroSeconds() {
        XCTAssertEqual(formatDuration(0.0), "0s")
    }

    func testFormatDuration_justBelowMinute() {
        XCTAssertEqual(formatDuration(59.9), "60s")
    }

    func testFormatDuration_exactMinute() {
        // 60s exactly → "1m" (secs == 0)
        XCTAssertEqual(formatDuration(60.0), "1m")
    }

    func testFormatDuration_minutesAndSeconds() {
        XCTAssertEqual(formatDuration(125.0), "2m 5s")
    }

    func testFormatDuration_exactMinutes() {
        // 120s → 2 minutes, 0 seconds → "2m"
        XCTAssertEqual(formatDuration(120.0), "2m")
    }

    func testFormatDuration_minutesOnly_noTrailingSeconds() {
        XCTAssertEqual(formatDuration(180.0), "3m")
    }

    func testFormatDuration_exactHour() {
        // 3600s → 1 hour, 0 minutes → "1h"
        XCTAssertEqual(formatDuration(3600.0), "1h")
    }

    func testFormatDuration_hoursAndMinutes() {
        // 3725s = 1h 2m 5s → "1h 2m"
        XCTAssertEqual(formatDuration(3725.0), "1h 2m")
    }

    func testFormatDuration_hoursOnly_noTrailingMinutes() {
        // 7200s = 2h exactly → "2h"
        XCTAssertEqual(formatDuration(7200.0), "2h")
    }

    func testFormatDuration_multipleHours() {
        // 10800s = 3h → "3h"
        XCTAssertEqual(formatDuration(10800.0), "3h")
    }

    // MARK: formatPercent (Double)

    func testFormatPercent_normal() {
        XCTAssertEqual(formatPercent(0.95), "95.0%")
    }

    func testFormatPercent_zero() {
        XCTAssertEqual(formatPercent(0.0), "0.0%")
    }

    func testFormatPercent_full() {
        XCTAssertEqual(formatPercent(1.0), "100.0%")
    }

    func testFormatPercent_half() {
        XCTAssertEqual(formatPercent(0.5), "50.0%")
    }

    func testFormatPercent_fractional() {
        XCTAssertEqual(formatPercent(0.333), "33.3%")
    }

    // MARK: formatPercent (Double?)

    func testFormatPercent_nil() {
        let value: Double? = nil
        XCTAssertEqual(formatPercent(value), "—")
    }

    func testFormatPercent_optionalWithValue() {
        let value: Double? = 0.75
        XCTAssertEqual(formatPercent(value), "75.0%")
    }

    // MARK: formatCount

    func testFormatCount_small() {
        XCTAssertEqual(formatCount(42), "42")
    }

    func testFormatCount_zero() {
        XCTAssertEqual(formatCount(0), "0")
    }

    func testFormatCount_thousands() {
        XCTAssertEqual(formatCount(1000), "1,000")
    }

    func testFormatCount_large() {
        XCTAssertEqual(formatCount(1_234_567), "1,234,567")
    }

    func testFormatCount_exact_million() {
        XCTAssertEqual(formatCount(1_000_000), "1,000,000")
    }

    // =========================================================================
    // MARK: - TasksViewModel Tests
    // =========================================================================

    func testTasksViewModel_initialState_isEmpty() {
        let vm = TasksViewModel()
        XCTAssertTrue(vm.tasks.isEmpty)
        XCTAssertTrue(vm.projects.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }

    func testFilteredTasks_filtersByStatus() {
        let vm = TasksViewModel()
        vm.tasks = [
            makeTask(id: "t1", status: .active),
            makeTask(id: "t2", status: .inbox),
            makeTask(id: "t3", status: .active),
            makeTask(id: "t4", status: .completed),
        ]

        let active = vm.filteredTasks(for: .active)
        XCTAssertEqual(active.count, 2)
        XCTAssertTrue(active.allSatisfy { $0.status == .active })
    }

    func testFilteredTasks_sortsBySortOrder() {
        let vm = TasksViewModel()
        vm.tasks = [
            makeTask(id: "t1", status: .active, sortOrder: 3),
            makeTask(id: "t2", status: .active, sortOrder: 1),
            makeTask(id: "t3", status: .active, sortOrder: 2),
        ]

        let result = vm.filteredTasks(for: .active)
        XCTAssertEqual(result.map { $0.id }, ["t2", "t3", "t1"])
    }

    func testFilteredTasks_nilSortOrderGoesLast() {
        let vm = TasksViewModel()
        vm.tasks = [
            makeTask(id: "t1", status: .active, sortOrder: nil),
            makeTask(id: "t2", status: .active, sortOrder: 1),
            makeTask(id: "t3", status: .active, sortOrder: 2),
        ]

        let result = vm.filteredTasks(for: .active)
        // nil treated as 999, so t2(1), t3(2), t1(999)
        XCTAssertEqual(result.first?.id, "t2")
        XCTAssertEqual(result.last?.id, "t1")
    }

    func testFilteredTasks_emptyForMissingStatus() {
        let vm = TasksViewModel()
        vm.tasks = [
            makeTask(id: "t1", status: .active),
            makeTask(id: "t2", status: .inbox),
        ]

        let result = vm.filteredTasks(for: .completed)
        XCTAssertTrue(result.isEmpty)
    }

    func testFilteredTasks_emptyTasks_returnsEmpty() {
        let vm = TasksViewModel()
        vm.tasks = []

        let result = vm.filteredTasks(for: .active)
        XCTAssertTrue(result.isEmpty)
    }

    func testFilteredTasks_singleMatch() {
        let vm = TasksViewModel()
        vm.tasks = [
            makeTask(id: "t1", status: .active),
            makeTask(id: "t2", status: .inbox),
        ]

        let result = vm.filteredTasks(for: .inbox)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "t2")
    }

    func testGroupedTasks_groupsByProjectId() {
        let vm = TasksViewModel()
        vm.tasks = [
            makeTask(id: "t1", status: .active, projectId: "proj-a"),
            makeTask(id: "t2", status: .active, projectId: "proj-b"),
            makeTask(id: "t3", status: .active, projectId: "proj-a"),
        ]

        let grouped = vm.groupedTasks(for: .active)
        XCTAssertEqual(grouped.keys.count, 2)
        XCTAssertEqual(grouped["proj-a"]?.count, 2)
        XCTAssertEqual(grouped["proj-b"]?.count, 1)
    }

    func testGroupedTasks_nilProjectId_usesDefault() {
        let vm = TasksViewModel()
        vm.tasks = [
            makeTask(id: "t1", status: .active, projectId: nil),
            makeTask(id: "t2", status: .active, projectId: "proj-a"),
        ]

        let grouped = vm.groupedTasks(for: .active)
        XCTAssertNotNil(grouped["default"])
        XCTAssertEqual(grouped["default"]?.count, 1)
        XCTAssertEqual(grouped["default"]?.first?.id, "t1")
    }

    func testGroupedTasks_allNilProjectIds_usesDefault() {
        let vm = TasksViewModel()
        vm.tasks = [
            makeTask(id: "t1", status: .active, projectId: nil),
            makeTask(id: "t2", status: .active, projectId: nil),
        ]

        let grouped = vm.groupedTasks(for: .active)
        XCTAssertEqual(grouped.keys.count, 1)
        XCTAssertEqual(grouped["default"]?.count, 2)
    }

    func testGroupedTasks_emptyForWrongStatus() {
        let vm = TasksViewModel()
        vm.tasks = [
            makeTask(id: "t1", status: .active, projectId: "proj-a"),
        ]

        let grouped = vm.groupedTasks(for: .inbox)
        XCTAssertTrue(grouped.isEmpty)
    }

    // =========================================================================
    // MARK: - ChatViewModel Tests
    // =========================================================================

    func testChatViewModel_initialState() {
        let vm = ChatViewModel()
        XCTAssertTrue(vm.sessions.isEmpty)
        XCTAssertNil(vm.currentSession)
        XCTAssertTrue(vm.messages.isEmpty)
        XCTAssertFalse(vm.isSending)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }

    func testChatViewModel_initialState_noCurrentSession() {
        let vm = ChatViewModel()
        XCTAssertNil(vm.currentSession)
    }

    func testChatViewModel_initialState_notSending() {
        let vm = ChatViewModel()
        XCTAssertFalse(vm.isSending)
    }

    func testChatViewModel_initialState_notLoading() {
        let vm = ChatViewModel()
        XCTAssertFalse(vm.isLoading)
    }

    func testChatViewModel_initialState_noError() {
        let vm = ChatViewModel()
        XCTAssertNil(vm.error)
    }

    func testChatViewModel_initialState_emptyMessages() {
        let vm = ChatViewModel()
        XCTAssertTrue(vm.messages.isEmpty)
    }

    func testChatViewModel_initialState_emptySessions() {
        let vm = ChatViewModel()
        XCTAssertTrue(vm.sessions.isEmpty)
    }

    // =========================================================================
    // MARK: - InboxViewModel Tests
    // =========================================================================

    func testInboxViewModel_initialState() {
        let vm = InboxViewModel()
        XCTAssertTrue(vm.items.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }

    func testInboxViewModel_initialState_emptyItems() {
        let vm = InboxViewModel()
        XCTAssertEqual(vm.items.count, 0)
    }

    func testInboxViewModel_initialState_notLoading() {
        let vm = InboxViewModel()
        XCTAssertFalse(vm.isLoading)
    }

    func testInboxViewModel_initialState_noError() {
        let vm = InboxViewModel()
        XCTAssertNil(vm.error)
    }

    func testInboxViewModel_canSetItems() {
        let vm = InboxViewModel()
        vm.items = [
            InboxItem(
                id: "inbox/test.md",
                title: "Test Item",
                filename: "test.md",
                relativePath: "inbox/test.md",
                content: "Content here",
                contentIsTruncated: false,
                modifiedAt: now,
                isRead: false,
                summary: "Summary"
            )
        ]
        XCTAssertEqual(vm.items.count, 1)
        XCTAssertEqual(vm.items.first?.id, "inbox/test.md")
    }

    func testInboxViewModel_canSetError() {
        let vm = InboxViewModel()
        vm.error = "Connection failed"
        XCTAssertEqual(vm.error, "Connection failed")
    }

    // =========================================================================
    // MARK: - DashboardViewModel Tests
    // =========================================================================

    func testDashboardViewModel_initialState() {
        let vm = DashboardViewModel()
        XCTAssertNil(vm.overview)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }

    func testDashboardViewModel_initialState_overviewNil() {
        let vm = DashboardViewModel()
        XCTAssertNil(vm.overview)
    }

    func testDashboardViewModel_initialState_notLoading() {
        let vm = DashboardViewModel()
        XCTAssertFalse(vm.isLoading)
    }

    func testDashboardViewModel_initialState_noError() {
        let vm = DashboardViewModel()
        XCTAssertNil(vm.error)
    }

    func testDashboardViewModel_canSetLoading() {
        let vm = DashboardViewModel()
        vm.isLoading = true
        XCTAssertTrue(vm.isLoading)
    }

    func testDashboardViewModel_canSetError() {
        let vm = DashboardViewModel()
        vm.error = "Server unreachable"
        XCTAssertEqual(vm.error, "Server unreachable")
    }

    // =========================================================================
    // MARK: - UsageViewModel Tests
    // =========================================================================

    func testUsageViewModel_initialState() {
        let vm = UsageViewModel()
        XCTAssertEqual(vm.timeWindow, .day)
        XCTAssertNil(vm.summary)
        XCTAssertNil(vm.projection)
        XCTAssertTrue(vm.workerHistory.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }

    func testUsageViewModel_timeWindow_defaultsToDay() {
        let vm = UsageViewModel()
        XCTAssertEqual(vm.timeWindow, .day)
    }

    func testUsageViewModel_totalTokens_withNilSummary_returnsZero() {
        let vm = UsageViewModel()
        vm.summary = nil
        XCTAssertEqual(vm.totalTokens, 0)
    }

    func testUsageViewModel_totalTokens_withSummary_returnsSum() {
        let vm = UsageViewModel()
        vm.summary = makeUsageSummary(totalInputTokens: 1000, totalOutputTokens: 500)
        XCTAssertEqual(vm.totalTokens, 1500)
    }

    func testUsageViewModel_totalTokens_largeValues() {
        let vm = UsageViewModel()
        vm.summary = makeUsageSummary(totalInputTokens: 1_000_000, totalOutputTokens: 250_000)
        XCTAssertEqual(vm.totalTokens, 1_250_000)
    }

    func testUsageViewModel_totalTokens_zeroValues() {
        let vm = UsageViewModel()
        vm.summary = makeUsageSummary(totalInputTokens: 0, totalOutputTokens: 0)
        XCTAssertEqual(vm.totalTokens, 0)
    }

    func testUsageViewModel_successRate_withNilSummary_returnsZero() {
        let vm = UsageViewModel()
        vm.summary = nil
        XCTAssertEqual(vm.successRate, 0.0)
    }

    func testUsageViewModel_successRate_withZeroRequests_returnsZero() {
        let vm = UsageViewModel()
        vm.summary = makeUsageSummary(totalRequests: 0)
        XCTAssertEqual(vm.successRate, 0.0)
    }

    func testUsageViewModel_successRate_withNoErrors_returnsOne() {
        let vm = UsageViewModel()
        let provider = makeProviderSummary(requests: 100, errorRate: 0.0)
        vm.summary = makeUsageSummary(totalRequests: 100, byProvider: [provider])
        XCTAssertEqual(vm.successRate, 1.0, accuracy: 0.001)
    }

    func testUsageViewModel_successRate_withData_calculatesCorrectly() {
        let vm = UsageViewModel()
        // 100 requests, 10% error rate → 10 failed, 90 successful → 90%
        let provider = makeProviderSummary(requests: 100, errorRate: 0.10)
        vm.summary = makeUsageSummary(totalRequests: 100, byProvider: [provider])
        XCTAssertEqual(vm.successRate, 0.90, accuracy: 0.001)
    }

    func testUsageViewModel_successRate_allErrors_returnsZero() {
        let vm = UsageViewModel()
        let provider = makeProviderSummary(requests: 100, errorRate: 1.0)
        vm.summary = makeUsageSummary(totalRequests: 100, byProvider: [provider])
        XCTAssertEqual(vm.successRate, 0.0, accuracy: 0.001)
    }

    func testUsageViewModel_successRate_multipleProviders() {
        let vm = UsageViewModel()
        // Provider A: 80 requests, 0% error → 0 failed
        // Provider B: 20 requests, 50% error → 10 failed
        // Total: 100 requests, 10 failed → 90% success
        let providerA = makeProviderSummary(provider: "anthropic", requests: 80, errorRate: 0.0)
        let providerB = makeProviderSummary(provider: "openai", requests: 20, errorRate: 0.5)
        vm.summary = makeUsageSummary(totalRequests: 100, byProvider: [providerA, providerB])
        XCTAssertEqual(vm.successRate, 0.90, accuracy: 0.001)
    }

    func testUsageViewModel_costTrendData_withNilSummary_returnsEmpty() {
        let vm = UsageViewModel()
        vm.summary = nil
        XCTAssertTrue(vm.costTrendData.isEmpty)
    }

    func testUsageViewModel_costTrendData_withNilDailySeries_returnsEmpty() {
        let vm = UsageViewModel()
        vm.summary = makeUsageSummary(dailySeries: nil)
        XCTAssertTrue(vm.costTrendData.isEmpty)
    }

    func testUsageViewModel_costTrendData_withSummary_returnsDailySeries() {
        let vm = UsageViewModel()
        let points = [
            DailyCostPoint(date: now, costUsd: 1.23, provider: nil),
            DailyCostPoint(date: now.addingTimeInterval(-86400), costUsd: 0.89, provider: nil),
        ]
        vm.summary = makeUsageSummary(dailySeries: points)
        XCTAssertEqual(vm.costTrendData.count, 2)
        XCTAssertEqual(vm.costTrendData.first?.costUsd ?? 0, 1.23, accuracy: 0.001)
    }

    func testUsageViewModel_costTrendData_emptyDailySeries_returnsEmpty() {
        let vm = UsageViewModel()
        vm.summary = makeUsageSummary(dailySeries: [])
        XCTAssertTrue(vm.costTrendData.isEmpty)
    }

    // MARK: - TimeWindow Tests

    func testTimeWindow_defaultsToDay() {
        let vm = UsageViewModel()
        XCTAssertEqual(vm.timeWindow, .day)
    }

    func testTimeWindow_displayName_day() {
        XCTAssertEqual(TimeWindow.day.displayName, "Day")
    }

    func testTimeWindow_displayName_week() {
        XCTAssertEqual(TimeWindow.week.displayName, "Week")
    }

    func testTimeWindow_displayName_month() {
        XCTAssertEqual(TimeWindow.month.displayName, "Month")
    }

    func testTimeWindow_apiValue_matchesRawValue() {
        for window in TimeWindow.allCases {
            XCTAssertEqual(window.apiValue, window.rawValue, "apiValue must match rawValue for \(window)")
        }
    }

    func testTimeWindow_allCases_hasThreeCases() {
        XCTAssertEqual(TimeWindow.allCases.count, 3)
    }

    func testTimeWindow_allCases_containsExpected() {
        let cases = TimeWindow.allCases
        XCTAssertTrue(cases.contains(.day))
        XCTAssertTrue(cases.contains(.week))
        XCTAssertTrue(cases.contains(.month))
    }

    func testTimeWindow_rawValues() {
        XCTAssertEqual(TimeWindow.day.rawValue, "day")
        XCTAssertEqual(TimeWindow.week.rawValue, "week")
        XCTAssertEqual(TimeWindow.month.rawValue, "month")
    }

    func testTimeWindow_canBeChangedOnViewModel() {
        let vm = UsageViewModel()
        vm.timeWindow = .week
        XCTAssertEqual(vm.timeWindow, .week)
        vm.timeWindow = .month
        XCTAssertEqual(vm.timeWindow, .month)
    }

    // =========================================================================
    // MARK: - ProjectsViewModel Tests
    // =========================================================================

    func testProjectsViewModel_initialState() {
        let vm = ProjectsViewModel()
        XCTAssertTrue(vm.projects.isEmpty)
        XCTAssertFalse(vm.showArchived)
        XCTAssertNil(vm.selectedProject)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
        XCTAssertFalse(vm.showCreateSheet)
        XCTAssertNil(vm.editingProject)
        XCTAssertEqual(vm.newTitle, "")
        XCTAssertEqual(vm.newType, .kanban)
        XCTAssertEqual(vm.newNotes, "")
    }

    func testFilteredProjects_hidesArchived_whenShowArchivedFalse() {
        let vm = ProjectsViewModel()
        vm.projects = [
            makeProject(id: "p1", archived: false),
            makeProject(id: "p2", archived: true),
            makeProject(id: "p3", archived: false),
        ]
        vm.showArchived = false

        let result = vm.filteredProjects
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { !($0.archived ?? false) })
    }

    func testFilteredProjects_showsAll_whenShowArchivedTrue() {
        let vm = ProjectsViewModel()
        vm.projects = [
            makeProject(id: "p1", archived: false),
            makeProject(id: "p2", archived: true),
            makeProject(id: "p3", archived: false),
        ]
        vm.showArchived = true

        let result = vm.filteredProjects
        XCTAssertEqual(result.count, 3)
    }

    func testFilteredProjects_sortsBySortOrder() {
        let vm = ProjectsViewModel()
        vm.projects = [
            makeProject(id: "p1", archived: false, sortOrder: 3),
            makeProject(id: "p2", archived: false, sortOrder: 1),
            makeProject(id: "p3", archived: false, sortOrder: 2),
        ]

        let result = vm.filteredProjects
        XCTAssertEqual(result.map { $0.id }, ["p2", "p3", "p1"])
    }

    func testFilteredProjects_nilSortOrder_goesLast() {
        let vm = ProjectsViewModel()
        vm.projects = [
            makeProject(id: "p1", archived: false, sortOrder: nil),
            makeProject(id: "p2", archived: false, sortOrder: 1),
            makeProject(id: "p3", archived: false, sortOrder: 2),
        ]

        let result = vm.filteredProjects
        XCTAssertEqual(result.first?.id, "p2")
        XCTAssertEqual(result.last?.id, "p1")
    }

    func testFilteredProjects_nilArchivedTreatedAsNotArchived() {
        let vm = ProjectsViewModel()
        vm.projects = [
            makeProject(id: "p1", archived: nil),   // nil → treated as false
            makeProject(id: "p2", archived: false),
        ]
        vm.showArchived = false

        // Both should appear because archived ?? false == false
        let result = vm.filteredProjects
        XCTAssertEqual(result.count, 2)
    }

    func testFilteredProjects_empty_whenNoProjects() {
        let vm = ProjectsViewModel()
        vm.projects = []
        XCTAssertTrue(vm.filteredProjects.isEmpty)
    }

    func testActiveProjects_excludesArchived() {
        let vm = ProjectsViewModel()
        vm.projects = [
            makeProject(id: "p1", archived: false, sortOrder: 1),
            makeProject(id: "p2", archived: true, sortOrder: 2),
            makeProject(id: "p3", archived: false, sortOrder: 3),
        ]
        vm.showArchived = true  // show archived in filtered but active should still exclude

        let active = vm.activeProjects
        XCTAssertEqual(active.count, 2)
        XCTAssertTrue(active.allSatisfy { !($0.archived ?? false) })
    }

    func testArchivedProjects_onlyArchived() {
        let vm = ProjectsViewModel()
        vm.projects = [
            makeProject(id: "p1", archived: false),
            makeProject(id: "p2", archived: true),
            makeProject(id: "p3", archived: true),
        ]

        let archived = vm.archivedProjects
        XCTAssertEqual(archived.count, 2)
        XCTAssertTrue(archived.allSatisfy { $0.archived == true })
    }

    func testArchivedProjects_emptyWhenNoneArchived() {
        let vm = ProjectsViewModel()
        vm.projects = [
            makeProject(id: "p1", archived: false),
            makeProject(id: "p2", archived: false),
        ]

        XCTAssertTrue(vm.archivedProjects.isEmpty)
    }

    func testActiveProjects_emptyWhenAllArchived() {
        let vm = ProjectsViewModel()
        vm.showArchived = true
        vm.projects = [
            makeProject(id: "p1", archived: true),
            makeProject(id: "p2", archived: true),
        ]

        XCTAssertTrue(vm.activeProjects.isEmpty)
    }

    func testResetCreateForm_clearsState() {
        let vm = ProjectsViewModel()
        // Populate form state
        let project = makeProject(id: "p1", type: .research)
        vm.editingProject = project
        vm.newTitle = "Some Title"
        vm.newType = .research
        vm.newNotes = "Some notes"
        vm.showCreateSheet = true

        vm.resetCreateForm()

        XCTAssertNil(vm.editingProject)
        XCTAssertEqual(vm.newTitle, "")
        XCTAssertEqual(vm.newType, .kanban)
        XCTAssertEqual(vm.newNotes, "")
        XCTAssertFalse(vm.showCreateSheet)
    }

    func testPrepareEdit_populatesFormFields() {
        let vm = ProjectsViewModel()
        let project = Project(
            id: "proj-edit",
            title: "Editable Project",
            createdAt: now,
            updatedAt: now,
            notes: "My notes",
            archived: false,
            type: .research,
            sortOrder: 5
        )

        vm.prepareEdit(project)

        XCTAssertEqual(vm.editingProject?.id, "proj-edit")
        XCTAssertEqual(vm.newTitle, "Editable Project")
        XCTAssertEqual(vm.newType, .research)
        XCTAssertEqual(vm.newNotes, "My notes")
        XCTAssertTrue(vm.showCreateSheet)
    }

    func testPrepareEdit_nilNotes_populatesEmptyString() {
        let vm = ProjectsViewModel()
        let project = Project(
            id: "proj-no-notes",
            title: "No Notes Project",
            createdAt: now,
            updatedAt: now,
            notes: nil,
            archived: false,
            type: .kanban,
            sortOrder: nil
        )

        vm.prepareEdit(project)

        XCTAssertEqual(vm.newNotes, "")
    }

    func testPrepareEdit_nilType_defaultsToKanban() {
        let vm = ProjectsViewModel()
        let project = Project(
            id: "proj-no-type",
            title: "No Type Project",
            createdAt: now,
            updatedAt: now,
            notes: nil,
            archived: false,
            type: nil,   // nil type → resolvedType is .kanban
            sortOrder: nil
        )

        vm.prepareEdit(project)

        // resolvedType returns .kanban when type is nil
        XCTAssertEqual(vm.newType, .kanban)
    }

    func testFilteredProjects_multipleCalls_areConsistent() {
        let vm = ProjectsViewModel()
        vm.projects = [
            makeProject(id: "p1", archived: false, sortOrder: 2),
            makeProject(id: "p2", archived: false, sortOrder: 1),
        ]

        let first = vm.filteredProjects
        let second = vm.filteredProjects
        XCTAssertEqual(first.map { $0.id }, second.map { $0.id })
    }
}
