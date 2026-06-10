package com.shuimingbai.clipboardexpense.ui

import com.shuimingbai.clipboardexpense.data.ExpenseRecord
import java.math.BigDecimal
import java.util.Calendar
import java.util.Date

data class PeriodStats(val total: BigDecimal, val count: Int)

object StatsCalculator {
    fun today(records: List<ExpenseRecord>): PeriodStats = sum(filterToday(records))
    fun thisWeek(records: List<ExpenseRecord>): PeriodStats = sum(filterThisWeek(records))
    fun thisMonth(records: List<ExpenseRecord>): PeriodStats = sum(filterThisMonth(records))

    fun groupByDay(records: List<ExpenseRecord>): List<Pair<String, List<ExpenseRecord>>> {
        val fmt = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.CHINA)
        return records.groupBy { fmt.format(it.time) }
            .toList()
            .sortedByDescending { it.first }
    }

    private fun sum(list: List<ExpenseRecord>) = PeriodStats(
        total = list.fold(BigDecimal.ZERO) { acc, r -> acc + r.amount },
        count = list.size
    )

    private fun filterToday(records: List<ExpenseRecord>): List<ExpenseRecord> {
        val cal = Calendar.getInstance()
        return records.filter { sameDay(it.time, cal) }
    }

    private fun filterThisWeek(records: List<ExpenseRecord>): List<ExpenseRecord> {
        val cal = Calendar.getInstance()
        cal.firstDayOfWeek = Calendar.MONDAY
        cal.set(Calendar.DAY_OF_WEEK, Calendar.MONDAY)
        zeroTime(cal)
        val start = cal.timeInMillis
        return records.filter { it.time.time >= start }
    }

    private fun filterThisMonth(records: List<ExpenseRecord>): List<ExpenseRecord> {
        val cal = Calendar.getInstance()
        cal.set(Calendar.DAY_OF_MONTH, 1)
        zeroTime(cal)
        val start = cal.timeInMillis
        return records.filter { it.time.time >= start }
    }

    private fun sameDay(date: Date, ref: Calendar): Boolean {
        val c = Calendar.getInstance()
        c.time = date
        return c.get(Calendar.YEAR) == ref.get(Calendar.YEAR) &&
            c.get(Calendar.DAY_OF_YEAR) == ref.get(Calendar.DAY_OF_YEAR)
    }

    private fun zeroTime(cal: Calendar) {
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
    }
}
