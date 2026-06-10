package com.shuimingbai.clipboardexpense.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.math.BigDecimal
import java.util.Date

@Entity(tableName = "expense_records")
data class ExpenseRecord(
    @PrimaryKey val id: String = java.util.UUID.randomUUID().toString(),
    val amount: BigDecimal,
    val category: String,
    val note: String? = null,
    val merchant: String? = null,
    val time: Date,
    val source: String,
    val rawText: String? = null
)
