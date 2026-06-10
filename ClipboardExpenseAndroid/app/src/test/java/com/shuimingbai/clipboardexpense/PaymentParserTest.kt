package com.shuimingbai.clipboardexpense

import com.shuimingbai.clipboardexpense.parser.PaymentParser
import com.shuimingbai.clipboardexpense.parser.PaymentSource
import org.junit.Assert.*
import org.junit.Test
import java.math.BigDecimal

class PaymentParserTest {
    @Test
    fun alipaySample() {
        val p = PaymentParser.parse("支付宝-向商家付款 ￥18.50 全家便利店")!!
        assertEquals(BigDecimal("18.50"), p.amount)
        assertEquals("全家便利店", p.merchant)
    }

    @Test
    fun wechatNotification() {
        val p = PaymentParser.parse("你向杭州余杭区良渚陈素红副食品店付款14.00元")!!
        assertEquals(BigDecimal("14.00"), p.amount)
        assertEquals(PaymentSource.WECHAT, p.source)
    }

    @Test
    fun structuredNotification() {
        val text = """
            消费金额：: 9.9元
            消费门店：: 兴老大·单县羊肉汤（严村里店）
        """.trimIndent()
        val p = PaymentParser.parse(text)!!
        assertEquals(BigDecimal("9.9"), p.amount)
        assertTrue(p.merchant!!.contains("羊肉汤"))
    }
}
