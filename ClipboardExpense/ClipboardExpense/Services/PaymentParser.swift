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
        "滴滴": "交通",
        "美团": "餐饮",
        "外卖": "餐饮"
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
            amountGroup: 1,
            merchantGroup: 2,
            confidence: .high
        ),
        ParserRule(
            source: .wechat,
            pattern: #"微信支付.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)"#,
            amountGroup: 1,
            merchantGroup: 2,
            confidence: .high
        ),
        ParserRule(
            source: .bank,
            pattern: #"消费(\d+(?:\.\d{1,2})?)元\s*(.+)"#,
            amountGroup: 1,
            merchantGroup: 2,
            confidence: .high
        ),
        ParserRule(
            source: .meituan,
            pattern: #"美团.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)"#,
            amountGroup: 1,
            merchantGroup: 2,
            confidence: .high
        ),
        ParserRule(
            source: .jd,
            pattern: #"京东.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)"#,
            amountGroup: 1,
            merchantGroup: 2,
            confidence: .medium
        ),
        ParserRule(
            source: .pinduoduo,
            pattern: #"拼多多.*?[¥￥](\d+(?:\.\d{1,2})?)\s*(.+)"#,
            amountGroup: 1,
            merchantGroup: 2,
            confidence: .medium
        )
    ]

    static func parse(_ text: String) -> ParsedPayment? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        for rule in rules {
            if let result = match(rule: rule, in: trimmed) {
                return result
            }
        }

        return parseGeneric(trimmed)
    }

    private static func match(rule: ParserRule, in text: String) -> ParsedPayment? {
        guard let regex = try? NSRegularExpression(pattern: rule.pattern, options: []),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }

        guard let amount = decimal(from: text, match: match, group: rule.amountGroup) else {
            return nil
        }

        let merchant = rule.merchantGroup.flatMap { group in
            string(from: text, match: match, group: group)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
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
            #"(\d+(?:\.\d{1,2})?)\s*元"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
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
        let patterns = [
            #"(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})"#,
            #"(\d{2})-(\d{2})\s+(\d{2}):(\d{2})"#
        ]

        let calendar = Calendar.current
        let now = Date()

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
                continue
            }

            if pattern.contains("yyyy") || match.numberOfRanges == 6 {
                guard let y = int(from: text, match: match, group: 1),
                      let m = int(from: text, match: match, group: 2),
                      let d = int(from: text, match: match, group: 3),
                      let h = int(from: text, match: match, group: 4),
                      let min = int(from: text, match: match, group: 5) else { continue }
                var components = DateComponents()
                components.year = y
                components.month = m
                components.day = d
                components.hour = h
                components.minute = min
                if let date = calendar.date(from: components) { return date }
            } else {
                guard let m = int(from: text, match: match, group: 1),
                      let d = int(from: text, match: match, group: 2),
                      let h = int(from: text, match: match, group: 3),
                      let min = int(from: text, match: match, group: 4) else { continue }
                var components = calendar.dateComponents([.year], from: now)
                components.month = m
                components.day = d
                components.hour = h
                components.minute = min
                if let date = calendar.date(from: components) { return date }
            }
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
