import Foundation

enum PaymentSource: String, Codable, CaseIterable {
    case alipay
    case wechat
    case bank
    case meituan
    case jd
    case pinduoduo
    case generic
    case manual

    var displayName: String {
        switch self {
        case .alipay: return "支付宝"
        case .wechat: return "微信支付"
        case .bank: return "银行"
        case .meituan: return "美团"
        case .jd: return "京东"
        case .pinduoduo: return "拼多多"
        case .generic: return "通用"
        case .manual: return "手动"
        }
    }
}

enum ParseConfidence: String, Codable {
    case low
    case medium
    case high
}

struct ParsedPayment: Equatable {
    let amount: Decimal
    let merchant: String?
    let category: String
    let time: Date
    let source: PaymentSource
    let confidence: ParseConfidence
    let rawText: String
}

struct PaymentParser {
    private static let merchantCategoryMap: [String: String] = [
        "麦当劳": "餐饮",
        "肯德基": "餐饮",
        "星巴克": "餐饮",
        "全家": "餐饮",
        "便利店": "购物",
        "副食品": "购物",
        "超市": "购物",
        "滴滴": "交通",
        "美团": "餐饮",
        "外卖": "餐饮",
        "羊肉汤": "餐饮",
        "饭店": "餐饮",
        "餐厅": "餐饮",
        "火锅": "餐饮",
        "咖啡": "餐饮",
        "奶茶": "餐饮"
    ]

    private static let billCategoryPatterns: [(String, String)] = [
        (#"餐饮|美食|下馆"#, "餐饮"),
        (#"购物|超市|副食|日用"#, "购物"),
        (#"交通|出行|打车|地铁"#, "交通"),
        (#"生活|缴费|充值"#, "生活"),
        (#"娱乐|游戏|电影"#, "娱乐")
    ]

    private struct ParserRule {
        let source: PaymentSource
        let pattern: String
        let amountGroup: Int
        let merchantGroup: Int?
        let confidence: ParseConfidence
    }

    private static let rules: [ParserRule] = [
        ParserRule(
            source: .alipay,
            pattern: #"(?:支付宝).*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)"#,
            amountGroup: 1, merchantGroup: 2, confidence: .high
        ),
        ParserRule(
            source: .wechat,
            pattern: #"微信支付.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)"#,
            amountGroup: 1, merchantGroup: 2, confidence: .high
        ),
        ParserRule(
            source: .wechat,
            pattern: #"向(.+?)付款(\d+(?:\.\d{1,2})?)元"#,
            amountGroup: 2, merchantGroup: 1, confidence: .high
        ),
        ParserRule(
            source: .wechat,
            pattern: #"付款(\d+(?:\.\d{1,2})?)元"#,
            amountGroup: 1, merchantGroup: nil, confidence: .medium
        ),
        ParserRule(
            source: .bank,
            pattern: #"消费(\d+(?:\.\d{1,2})?)元\s*(.+)"#,
            amountGroup: 1, merchantGroup: 2, confidence: .high
        ),
        ParserRule(
            source: .meituan,
            pattern: #"美团.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)"#,
            amountGroup: 1, merchantGroup: 2, confidence: .high
        ),
        ParserRule(
            source: .jd,
            pattern: #"京东.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)"#,
            amountGroup: 1, merchantGroup: 2, confidence: .medium
        ),
        ParserRule(
            source: .pinduoduo,
            pattern: #"拼多多.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)"#,
            amountGroup: 1, merchantGroup: 2, confidence: .medium
        ),
        ParserRule(
            source: .alipay,
            pattern: #"消费(\d+(?:\.\d{1,2})?)元"#,
            amountGroup: 1, merchantGroup: nil, confidence: .medium
        )
    ]

    static func parse(_ text: String) -> ParsedPayment? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let structured = parseStructuredFields(trimmed) { return structured }
        if let bill = parseBillDetail(trimmed) { return bill }

        for rule in rules {
            if let result = match(rule: rule, in: trimmed) { return result }
        }

        return parseGeneric(trimmed)
    }

    // MARK: - Structured notification (消费金额 / 消费门店)

    private static func parseStructuredFields(_ text: String) -> ParsedPayment? {
        guard let amountRegex = try? NSRegularExpression(pattern: #"消费金额[:：]+\s*:?\s*(\d+(?:\.\d{1,2})?)\s*元?"#),
              let amountMatch = amountRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let amount = decimal(from: text, match: amountMatch, group: 1) else {
            return nil
        }

        let merchantRegex = try? NSRegularExpression(pattern: #"消费门店[:：]+\s*:?\s*(.+?)(?:\r?\n|$)"#)
        let merchant = merchantRegex
            .flatMap { $0.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) }
            .flatMap { string(from: text, match: $0, group: 1)?.trimmingCharacters(in: .whitespacesAndNewlines) }

        let source: PaymentSource = text.contains("支付宝") ? .alipay : text.contains("微信") ? .wechat : .generic

        return ParsedPayment(
            amount: amount,
            merchant: merchant?.isEmpty == true ? nil : merchant,
            category: categorize(merchant: merchant, text: text),
            time: extractTime(from: text) ?? .now,
            source: source,
            confidence: merchant != nil ? .high : .medium,
            rawText: text
        )
    }

    // MARK: - Bill detail page text

    private static func parseBillDetail(_ text: String) -> ParsedPayment? {
        let isBill = (text.contains("账单详情") || text.contains("账单"))
            && (text.contains("支付成功") || text.contains("交易成功") || text.contains("支付时间"))
        guard isBill else { return nil }

        let amount: Decimal?
        if let negRegex = try? NSRegularExpression(pattern: #"(?:^|\n)\s*-(\d+(?:\.\d{1,2})?)\s*(?:\n|$)"#, options: [.anchorsMatchLines]),
           let m = negRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            amount = decimal(from: text, match: m, group: 1)
        } else if let mRegex = try? NSRegularExpression(pattern: #"消费金额[:：]+\s*:?\s*(\d+(?:\.\d{1,2})?)"#),
                  let m = mRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            amount = decimal(from: text, match: m, group: 1)
        } else {
            amount = nil
        }
        guard let amount else { return nil }

        var merchant: String?
        if let mRegex = try? NSRegularExpression(pattern: #"商户全称[:：]\s*(.+?)(?:\r?\n|$)"#),
           let m = mRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            merchant = string(from: text, match: m, group: 1)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if merchant == nil, let mRegex = try? NSRegularExpression(pattern: #"商品[:：]\s*(.+?)(?:\r?\n|$)"#),
           let m = mRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            merchant = string(from: text, match: m, group: 1)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "-消费", with: "")
        }
        if merchant == nil {
            merchant = merchantFromBillLines(text)
        }

        let catLabel = extractLabel(text, keys: ["账单分类"])
        let category = mapBillCategory(catLabel) ?? categorize(merchant: merchant, text: text)

        var source: PaymentSource = .generic
        if text.contains("微信") || text.contains("零钱") || text.contains("财付通") { source = .wechat }
        else if text.contains("支付宝") || text.contains("余额宝") || text.contains("花呗") { source = .alipay }

        return ParsedPayment(
            amount: amount,
            merchant: merchant?.isEmpty == true ? nil : merchant,
            category: category,
            time: extractTime(from: text) ?? .now,
            source: source,
            confidence: merchant != nil ? .high : .medium,
            rawText: text
        )
    }

    private static func merchantFromBillLines(_ text: String) -> String? {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard let billIdx = lines.firstIndex(where: { $0 == "账单详情" || $0 == "账单" }) else { return nil }
        for i in (billIdx + 1)..<min(billIdx + 4, lines.count) {
            let line = lines[i]
            if line.range(of: #"^-?\d+(\.\d+)?$"#, options: .regularExpression) != nil { continue }
            if line.contains("成功") || line.contains("状态") { continue }
            return line.replacingOccurrences(of: "-消费", with: "")
        }
        return nil
    }

    private static func extractLabel(_ text: String, keys: [String]) -> String? {
        for key in keys {
            let pattern = "\(key)[:：]?\\s*(?:\\r?\\n\\s*)?(.+?)(?:\\r?\\n|$)"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let value = string(from: text, match: m, group: 1)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private static func mapBillCategory(_ label: String?) -> String? {
        guard let label else { return nil }
        for (pattern, category) in billCategoryPatterns {
            if label.range(of: pattern, options: .regularExpression) != nil { return category }
        }
        return nil
    }

    // MARK: - Rule / generic

    private static func match(rule: ParserRule, in text: String) -> ParsedPayment? {
        guard let regex = try? NSRegularExpression(pattern: rule.pattern, options: []),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let amount = decimal(from: text, match: match, group: rule.amountGroup) else {
            return nil
        }

        let merchant = rule.merchantGroup.flatMap { group in
            string(from: text, match: match, group: group)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return ParsedPayment(
            amount: amount,
            merchant: merchant?.isEmpty == true ? nil : merchant,
            category: categorize(merchant: merchant, text: text),
            time: extractTime(from: text) ?? .now,
            source: rule.source,
            confidence: rule.confidence,
            rawText: text
        )
    }

    private static func parseGeneric(_ text: String) -> ParsedPayment? {
        let patterns = [
            #"[¥￥]\s*(\d+(?:\.\d{1,2})?)"#,
            #"(\d+(?:\.\d{1,2})?)\s*元"#,
            #"(?:^|\n)\s*-(\d+(?:\.\d{1,2})?)\s*(?:\n|$)"#
        ]

        for pattern in patterns {
            let options: NSRegularExpression.Options = pattern.contains("^") ? [.anchorsMatchLines] : []
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let amount = decimal(from: text, match: match, group: 1) else {
                continue
            }

            return ParsedPayment(
                amount: amount,
                merchant: nil,
                category: categorize(merchant: nil, text: text),
                time: extractTime(from: text) ?? .now,
                source: .generic,
                confidence: .low,
                rawText: text
            )
        }
        return nil
    }

    private static func decimal(from text: String, match: NSTextCheckingResult, group: Int) -> Decimal? {
        guard let value = string(from: text, match: match, group: group) else { return nil }
        return Decimal(string: value)
    }

    private static func string(from text: String, match: NSTextCheckingResult, group: Int) -> String? {
        let range = match.range(at: group)
        guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else { return nil }
        return String(text[swiftRange])
    }

    private static func extractTime(from text: String) -> Date? {
        let specs: [(String, Bool)] = [
            (#"支付时间\s*(?:[:：]\s*)?(?:\r?\n\s*)?(\d{4})年(\d{1,2})月(\d{1,2})日\s*(\d{1,2}):(\d{2}):(\d{2})"#, true),
            (#"支付时间\s*(?:[:：]\s*)?(?:\r?\n\s*)?(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})"#, true),
            (#"支付时间\s*(?:[:：]\s*)?(?:\r?\n\s*)?(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})"#, false),
            (#"消费时间[:：]+\s*:?\s*(\d{4})年(\d{1,2})月(\d{1,2})日\s*(\d{1,2}):(\d{2})"#, false),
            (#"(\d{4})年(\d{1,2})月(\d{1,2})日\s*(\d{1,2}):(\d{2}):(\d{2})"#, true),
            (#"(\d{4})年(\d{1,2})月(\d{1,2})日\s*(\d{1,2}):(\d{2})"#, false),
            (#"(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})"#, false)
        ]

        let calendar = Calendar.current
        let now = Date()

        for (pattern, hasSeconds) in specs {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
                continue
            }
            if hasSeconds,
               let y = int(from: text, match: match, group: 1),
               let mo = int(from: text, match: match, group: 2),
               let d = int(from: text, match: match, group: 3),
               let h = int(from: text, match: match, group: 4),
               let mi = int(from: text, match: match, group: 5),
               let s = int(from: text, match: match, group: 6) {
                var c = DateComponents()
                c.year = y; c.month = mo; c.day = d; c.hour = h; c.minute = mi; c.second = s
                if let date = calendar.date(from: c) { return date }
            } else if let y = int(from: text, match: match, group: 1),
                      let mo = int(from: text, match: match, group: 2),
                      let d = int(from: text, match: match, group: 3),
                      let h = int(from: text, match: match, group: 4),
                      let mi = int(from: text, match: match, group: 5) {
                var c = DateComponents()
                c.year = y; c.month = mo; c.day = d; c.hour = h; c.minute = mi
                if let date = calendar.date(from: c) { return date }
            }
        }

        if let mRegex = try? NSRegularExpression(pattern: #"(\d{2})-(\d{2})\s+(\d{2}):(\d{2})"#),
           let m = mRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let mo = int(from: text, match: m, group: 1),
           let d = int(from: text, match: m, group: 2),
           let h = int(from: text, match: m, group: 3),
           let mi = int(from: text, match: m, group: 4) {
            var c = calendar.dateComponents([.year], from: now)
            c.month = mo; c.day = d; c.hour = h; c.minute = mi
            return calendar.date(from: c)
        }

        return nil
    }

    private static func int(from text: String, match: NSTextCheckingResult, group: Int) -> Int? {
        guard let value = string(from: text, match: match, group: group) else { return nil }
        return Int(value)
    }

    static func categorize(merchant: String?, text: String) -> String {
        let candidates = [merchant, text].compactMap { $0 }
        for candidate in candidates {
            for (keyword, category) in merchantCategoryMap where candidate.contains(keyword) {
                return category
            }
        }
        return "其他"
    }
}
