package com.shuimingbai.clipboardexpense.parser

import java.math.BigDecimal
import java.time.LocalDateTime
import java.time.ZoneId
import java.util.Date

enum class PaymentSource(val label: String) {
    ALIPAY("支付宝"),
    WECHAT("微信支付"),
    BANK("银行"),
    MEITUAN("美团"),
    JD("京东"),
    PINDUODUO("拼多多"),
    GENERIC("通用"),
    MANUAL("手动")
}

enum class ParseConfidence { LOW, MEDIUM, HIGH }

data class ParsedPayment(
    val amount: BigDecimal,
    val merchant: String?,
    val category: String,
    val time: Date,
    val source: PaymentSource,
    val confidence: ParseConfidence,
    val rawText: String
) {
    companion object {
        fun manualFallback(rawText: String) = ParsedPayment(
            amount = BigDecimal.ZERO,
            merchant = null,
            category = "其他",
            time = Date(),
            source = PaymentSource.MANUAL,
            confidence = ParseConfidence.LOW,
            rawText = rawText
        )
    }
}

object PaymentParser {
    private val merchantCategoryMap = mapOf(
        "麦当劳" to "餐饮", "肯德基" to "餐饮", "星巴克" to "餐饮", "全家" to "餐饮",
        "便利店" to "购物", "副食品" to "购物", "超市" to "购物", "滴滴" to "交通",
        "美团" to "餐饮", "外卖" to "餐饮", "羊肉汤" to "餐饮", "饭店" to "餐饮",
        "餐厅" to "餐饮", "火锅" to "餐饮", "咖啡" to "餐饮", "奶茶" to "餐饮"
    )

    private data class Rule(
        val source: PaymentSource,
        val pattern: Regex,
        val amountGroup: Int,
        val merchantGroup: Int?,
        val confidence: ParseConfidence
    )

    private val rules = listOf(
        Rule(PaymentSource.ALIPAY, """(?:支付宝).*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)""".toRegex(), 1, 2, ParseConfidence.HIGH),
        Rule(PaymentSource.WECHAT, """微信支付.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)""".toRegex(), 1, 2, ParseConfidence.HIGH),
        Rule(PaymentSource.WECHAT, """向(.+?)付款(\d+(?:\.\d{1,2})?)元""".toRegex(), 2, 1, ParseConfidence.HIGH),
        Rule(PaymentSource.WECHAT, """付款(\d+(?:\.\d{1,2})?)元""".toRegex(), 1, null, ParseConfidence.MEDIUM),
        Rule(PaymentSource.BANK, """消费(\d+(?:\.\d{1,2})?)元\s*(.+)""".toRegex(), 1, 2, ParseConfidence.HIGH),
        Rule(PaymentSource.MEITUAN, """美团.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)""".toRegex(), 1, 2, ParseConfidence.HIGH),
        Rule(PaymentSource.ALIPAY, """消费(\d+(?:\.\d{1,2})?)元""".toRegex(), 1, null, ParseConfidence.MEDIUM)
    )

    fun parse(text: String): ParsedPayment? {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return null

        parseStructuredFields(trimmed)?.let { return it }
        parseBillDetail(trimmed)?.let { return it }

        for (rule in rules) {
            matchRule(rule, trimmed)?.let { return it }
        }

        return parseGeneric(trimmed)
    }

    private fun parseStructuredFields(text: String): ParsedPayment? {
        val amountMatch = """消费金额[:：]+\s*:?\s*(\d+(?:\.\d{1,2})?)\s*元?""".toRegex().find(text) ?: return null
        val amount = amountMatch.groupValues[1].toBigDecimalOrNull() ?: return null
        val merchant = """消费门店[:：]+\s*:?\s*(.+?)(?:\r?\n|$)""".toRegex().find(text)
            ?.groupValues?.get(1)?.trim()?.ifEmpty { null }
        val source = when {
            text.contains("支付宝") -> PaymentSource.ALIPAY
            text.contains("微信") -> PaymentSource.WECHAT
            else -> PaymentSource.GENERIC
        }
        return ParsedPayment(
            amount = amount,
            merchant = merchant,
            category = categorize(merchant, text),
            time = extractTime(text) ?: Date(),
            source = source,
            confidence = if (merchant != null) ParseConfidence.HIGH else ParseConfidence.MEDIUM,
            rawText = text
        )
    }

    private fun parseBillDetail(text: String): ParsedPayment? {
        val isBill = (text.contains("账单详情") || text.contains("账单")) &&
            (text.contains("支付成功") || text.contains("交易成功") || text.contains("支付时间"))
        if (!isBill) return null

        val amount = """(?:^|\n)\s*-(\d+(?:\.\d{1,2})?)\s*(?:\n|$)""".toRegex(RegexOption.MULTILINE)
            .find(text)?.groupValues?.get(1)?.toBigDecimalOrNull()
            ?: """消费金额[:：]+\s*:?\s*(\d+(?:\.\d{1,2})?)""".toRegex().find(text)
                ?.groupValues?.get(1)?.toBigDecimalOrNull()
            ?: return null

        var merchant = """商户全称[:：]\s*(.+?)(?:\r?\n|$)""".toRegex().find(text)?.groupValues?.get(1)?.trim()
        if (merchant.isNullOrEmpty()) {
            merchant = """商品[:：]\s*(.+?)(?:\r?\n|$)""".toRegex().find(text)
                ?.groupValues?.get(1)?.trim()?.removeSuffix("-消费")
        }
        if (merchant.isNullOrEmpty()) {
            merchant = merchantFromBillLines(text)
        }

        val catLabel = """账单分类[:：]?\s*(?:\r?\n\s*)?(.+?)(?:\r?\n|$)""".toRegex().find(text)?.groupValues?.get(1)?.trim()
        val category = mapBillCategory(catLabel) ?: categorize(merchant, text)

        val source = when {
            text.contains("微信") || text.contains("零钱") -> PaymentSource.WECHAT
            text.contains("支付宝") || text.contains("余额宝") -> PaymentSource.ALIPAY
            else -> PaymentSource.GENERIC
        }

        return ParsedPayment(
            amount = amount,
            merchant = merchant,
            category = category,
            time = extractTime(text) ?: Date(),
            source = source,
            confidence = if (!merchant.isNullOrEmpty()) ParseConfidence.HIGH else ParseConfidence.MEDIUM,
            rawText = text
        )
    }

    private fun merchantFromBillLines(text: String): String? {
        val lines = text.lines().map { it.trim() }.filter { it.isNotEmpty() }
        val billIdx = lines.indexOfFirst { it == "账单详情" || it == "账单" }
        if (billIdx < 0) return null
        for (i in (billIdx + 1) until minOf(billIdx + 4, lines.size)) {
            val line = lines[i]
            if (line.matches(Regex("^-?\\d+(\\.\\d+)?$"))) continue
            if (line.contains("成功") || line.contains("状态")) continue
            return line.removeSuffix("-消费")
        }
        return null
    }

    private fun mapBillCategory(label: String?): String? {
        if (label.isNullOrEmpty()) return null
        return when {
            label.contains(Regex("餐饮|美食|下馆")) -> "餐饮"
            label.contains(Regex("购物|超市|副食")) -> "购物"
            label.contains(Regex("交通|出行|打车")) -> "交通"
            label.contains(Regex("生活|缴费")) -> "生活"
            label.contains(Regex("娱乐|游戏")) -> "娱乐"
            else -> null
        }
    }

    private fun matchRule(rule: Rule, text: String): ParsedPayment? {
        val m = rule.pattern.find(text) ?: return null
        val amount = m.groupValues.getOrNull(rule.amountGroup)?.toBigDecimalOrNull() ?: return null
        val merchant = rule.merchantGroup?.let { g ->
            m.groupValues.getOrNull(g)?.trim()?.ifEmpty { null }
        }
        return ParsedPayment(
            amount = amount,
            merchant = merchant,
            category = categorize(merchant, text),
            time = extractTime(text) ?: Date(),
            source = rule.source,
            confidence = rule.confidence,
            rawText = text
        )
    }

    private fun parseGeneric(text: String): ParsedPayment? {
        val patterns = listOf(
            """[¥￥]\s*(\d+(?:\.\d{1,2})?)""".toRegex(),
            """(\d+(?:\.\d{1,2})?)\s*元""".toRegex(),
            """(?:^|\n)\s*-(\d+(?:\.\d{1,2})?)\s*(?:\n|$)""".toRegex(RegexOption.MULTILINE)
        )
        for (p in patterns) {
            val m = p.find(text) ?: continue
            val amount = m.groupValues[1].toBigDecimalOrNull() ?: continue
            return ParsedPayment(
                amount = amount,
                merchant = null,
                category = categorize(null, text),
                time = extractTime(text) ?: Date(),
                source = PaymentSource.GENERIC,
                confidence = ParseConfidence.LOW,
                rawText = text
            )
        }
        return null
    }

    private fun extractTime(text: String): Date? {
        val patterns = listOf(
            """支付时间\s*(?:[:：]\s*)?(?:\r?\n\s*)?(\d{4})年(\d{1,2})月(\d{1,2})日\s*(\d{1,2}):(\d{2}):(\d{2})""".toRegex(),
            """支付时间\s*(?:[:：]\s*)?(?:\r?\n\s*)?(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})""".toRegex(),
            """支付时间\s*(?:[:：]\s*)?(?:\r?\n\s*)?(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})""".toRegex(),
            """消费时间[:：]+\s*:?\s*(\d{4})年(\d{1,2})月(\d{1,2})日\s*(\d{1,2}):(\d{2})""".toRegex(),
            """(\d{4})年(\d{1,2})月(\d{1,2})日\s*(\d{1,2}):(\d{2}):(\d{2})""".toRegex()
        )
        for (regex in patterns) {
            val m = regex.find(text) ?: continue
            val g = m.groupValues
            return try {
                val ldt = if (g.size >= 7) {
                    LocalDateTime.of(g[1].toInt(), g[2].toInt(), g[3].toInt(), g[4].toInt(), g[5].toInt(), g[6].toInt())
                } else {
                    LocalDateTime.of(g[1].toInt(), g[2].toInt(), g[3].toInt(), g[4].toInt(), g[5].toInt(), 0)
                }
                Date.from(ldt.atZone(ZoneId.systemDefault()).toInstant())
            } catch (_: Exception) {
                null
            }
        }
        return null
    }

    fun categorize(merchant: String?, text: String): String {
        val candidates = listOfNotNull(merchant, text.takeIf { it.isNotEmpty() })
        for (c in candidates) {
            for ((kw, cat) in merchantCategoryMap) {
                if (c.contains(kw)) return cat
            }
        }
        return "其他"
    }
}
