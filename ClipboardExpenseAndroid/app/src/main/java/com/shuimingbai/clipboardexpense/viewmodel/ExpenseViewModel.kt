package com.shuimingbai.clipboardexpense.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.shuimingbai.clipboardexpense.data.AppDatabase
import com.shuimingbai.clipboardexpense.data.CategoryStore
import com.shuimingbai.clipboardexpense.data.ExpenseRecord
import com.shuimingbai.clipboardexpense.parser.ParsedPayment
import com.shuimingbai.clipboardexpense.parser.PaymentParser
import com.shuimingbai.clipboardexpense.parser.PaymentSource
import com.shuimingbai.clipboardexpense.service.PendingConfirmStore
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.Date

class ExpenseViewModel(app: Application) : AndroidViewModel(app) {
    private val dao = AppDatabase.get(app).expenseDao()

    val records = dao.observeAll().stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _categories = MutableStateFlow(CategoryStore.all(app))
    val categories: StateFlow<List<String>> = _categories.asStateFlow()

    private val _confirmSheet = MutableStateFlow<ParsedPayment?>(null)
    val confirmSheet: StateFlow<ParsedPayment?> = _confirmSheet.asStateFlow()

    private val _clipboardHint = MutableStateFlow(false)
    val clipboardHint: StateFlow<Boolean> = _clipboardHint.asStateFlow()

    init {
        viewModelScope.launch {
            PendingConfirmStore.pending.collect { pending ->
                if (pending != null) _confirmSheet.value = pending
            }
        }
    }

    fun refreshCategories() {
        _categories.value = CategoryStore.all(getApplication())
    }

    fun addCategory(name: String) {
        CategoryStore.add(getApplication(), name)
        refreshCategories()
    }

    fun removeCategory(name: String) {
        CategoryStore.removeCustom(getApplication(), name)
        refreshCategories()
    }

    fun showClipboardHint() {
        _clipboardHint.value = true
    }

    fun dismissClipboardHint() {
        _clipboardHint.value = false
    }

    fun processText(text: String) {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return
        val parsed = PaymentParser.parse(trimmed) ?: ParsedPayment.manualFallback(trimmed)
        _confirmSheet.value = parsed
        dismissClipboardHint()
    }

    fun showConfirm(parsed: ParsedPayment) {
        _confirmSheet.value = parsed
    }

    fun dismissConfirm() {
        _confirmSheet.value = null
        PendingConfirmStore.clear()
    }

    fun saveFromParsed(
        amount: String,
        merchant: String,
        category: String,
        note: String,
        time: Date,
        source: PaymentSource,
        rawText: String
    ) {
        val value = amount.toBigDecimalOrNull() ?: return
        if (value <= java.math.BigDecimal.ZERO) return
        viewModelScope.launch {
            dao.insert(
                ExpenseRecord(
                    amount = value,
                    category = category.ifBlank { "其他" },
                    note = note.ifBlank { null },
                    merchant = merchant.ifBlank { null },
                    time = time,
                    source = source.name.lowercase(),
                    rawText = rawText.ifBlank { null }
                )
            )
            dismissConfirm()
        }
    }

    fun delete(record: ExpenseRecord) {
        viewModelScope.launch { dao.delete(record) }
    }
}
