import Foundation

struct PeriodStats: Equatable {
    let total: Decimal
    let count: Int
}

struct StatsCalculator {
    static func today(records: [ExpenseRecord], calendar: Calendar = .current) -> PeriodStats {
        sum(records.filter { calendar.isDateInToday($0.time) })
    }

    static func thisWeek(records: [ExpenseRecord], calendar: Calendar = .current) -> PeriodStats {
        sum(records.filter { calendar.isDate($0.time, equalTo: .now, toGranularity: .weekOfYear) })
    }

    static func thisMonth(records: [ExpenseRecord], calendar: Calendar = .current) -> PeriodStats {
        sum(records.filter { calendar.isDate($0.time, equalTo: .now, toGranularity: .month) })
    }

    static func groupedByDay(records: [ExpenseRecord], calendar: Calendar = .current) -> [(Date, [ExpenseRecord])] {
        let grouped = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.time)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { ($0.key, $0.value.sorted { $0.time > $1.time }) }
    }

    private static func sum(_ records: [ExpenseRecord]) -> PeriodStats {
        PeriodStats(
            total: records.reduce(Decimal.zero) { $0 + $1.amount },
            count: records.count
        )
    }
}
