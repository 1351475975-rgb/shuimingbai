package com.shuimingbai.clipboardexpense.service

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import com.shuimingbai.clipboardexpense.parser.PaymentParser
import java.math.BigDecimal

/**
 * 监听微信/支付宝支付通知（Android Pro 核心）
 * 需在 设置 → 通知使用权 中授权
 */
class PaymentNotificationListener : NotificationListenerService() {

    companion object {
        private val PAYMENT_PACKAGES = setOf(
            "com.tencent.mm",                    // 微信
            "com.eg.android.AlipayGphone",       // 支付宝
            "com.eg.android.AlipayGphoneRC"      // 支付宝内测
        )

        private val PAYMENT_KEYWORDS = listOf("支付", "付款", "消费", "元", "¥", "￥", "成功")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val pkg = sbn.packageName ?: return
        if (pkg !in PAYMENT_PACKAGES) return

        val text = extractText(sbn) ?: return
        if (!PAYMENT_KEYWORDS.any { text.contains(it) }) return

        val parsed = PaymentParser.parse(text) ?: return
        if (parsed.amount <= BigDecimal.ZERO) return

        PaymentNotificationHelper.showConfirmNotification(applicationContext, parsed)
    }

    private fun extractText(sbn: StatusBarNotification): String? {
        val extras = sbn.notification.extras
        val parts = listOfNotNull(
            extras.getCharSequence("android.title")?.toString(),
            extras.getCharSequence("android.text")?.toString(),
            extras.getCharSequence("android.bigText")?.toString(),
            extras.getCharSequence("android.subText")?.toString()
        ).filter { it.isNotBlank() }

        val combined = parts.joinToString("\n").trim()
        return combined.ifEmpty { null }
    }
}
