package com.shuimingbai.clipboardexpense.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface ExpenseDao {
    @Query("SELECT * FROM expense_records ORDER BY time DESC")
    fun observeAll(): Flow<List<ExpenseRecord>>

    @Insert
    suspend fun insert(record: ExpenseRecord)

    @Delete
    suspend fun delete(record: ExpenseRecord)
}
