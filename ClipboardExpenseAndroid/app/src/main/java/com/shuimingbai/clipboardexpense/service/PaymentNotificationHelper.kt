package com.shuimingbai.clipboardexpense.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.shuimingbai.clipboardexpense.MainActivity
import com.shuimingbai.clipboardexpense.R
import com.shuimingbai.clipboardexpense.parser.ParsedPayment
import java.math.BigDecimal
import java.text.NumberFormat
import java.util.Locale

object PaymentNotificationHelper {
    private const val CHANNEL_ID = "payment_confirm"
    private const val NOTIFICATION_ID = 1001

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.channel_payment),
            NotificationManager.IMPORTANCE_HIGH
        )
        mgr.createNotificationChannel(channel)
    }

    fun showConfirmNotification(context: Context, parsed: ParsedPayment) {
        ensureChannel(context)
        PendingConfirmStore.set(parsed)

        val intent = Intent(context, MainActivity::class.java).apply {
            action = MainActivity.ACTION_CONFIRM
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pi = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val fmt = NumberFormat.getCurrencyInstance(Locale.CHINA)
        val amountStr = fmt.format(parsed.amount)
        val title = context.getString(R.string.confirm_notification_title)
        val text = buildString {
            append(amountStr)
            parsed.merchant?.let { append(" · ").append(it) }
            append(" — 点击确认记账")
        }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(title)
            .setContentText(text)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pi)
            .build()

        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        mgr.notify(NOTIFICATION_ID, notification)
    }
}
