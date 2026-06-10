package com.shuimingbai.clipboardexpense.service

import com.shuimingbai.clipboardexpense.parser.ParsedPayment
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** 通知 / 剪贴板解析结果，等待 UI 确认 */
object PendingConfirmStore {
    private val _pending = MutableStateFlow<ParsedPayment?>(null)
    val pending: StateFlow<ParsedPayment?> = _pending.asStateFlow()

    fun set(parsed: ParsedPayment) {
        _pending.value = parsed
    }

    fun clear() {
        _pending.value = null
    }
}
