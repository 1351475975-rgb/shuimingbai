import XCTest
@testable import ClipboardExpense

final class PaymentParserTests: XCTestCase {
    func testAlipaySample() throws {
        let text = "支付宝-向商家付款 ￥18.50 全家便利店"
        let parsed = try XCTUnwrap(PaymentParser.parse(text))

        XCTAssertEqual(parsed.amount, Decimal(string: "18.50"))
        XCTAssertEqual(parsed.merchant, "全家便利店")
        XCTAssertEqual(parsed.source, .alipay)
        XCTAssertEqual(parsed.confidence, .high)
        XCTAssertEqual(parsed.category, "餐饮")
    }

    func testWechatSample() throws {
        let text = "微信支付 消费 ￥32.00 麦当劳"
        let parsed = try XCTUnwrap(PaymentParser.parse(text))

        XCTAssertEqual(parsed.amount, Decimal(string: "32.00"))
        XCTAssertEqual(parsed.merchant, "麦当劳")
        XCTAssertEqual(parsed.source, .wechat)
        XCTAssertEqual(parsed.category, "餐饮")
    }

    func testBankSample() throws {
        let text = "【招商银行】您尾号1234卡消费86.00元 星巴克"
        let parsed = try XCTUnwrap(PaymentParser.parse(text))

        XCTAssertEqual(parsed.amount, Decimal(string: "86.00"))
        XCTAssertEqual(parsed.merchant, "星巴克")
        XCTAssertEqual(parsed.source, .bank)
        XCTAssertEqual(parsed.category, "餐饮")
    }

    func testMeituanSample() throws {
        let text = "美团支付 ￥25.00 外卖订单"
        let parsed = try XCTUnwrap(PaymentParser.parse(text))

        XCTAssertEqual(parsed.amount, Decimal(string: "25.00"))
        XCTAssertEqual(parsed.merchant, "外卖订单")
        XCTAssertEqual(parsed.source, .meituan)
    }

    func testJDSample() throws {
        let text = "京东支付 ￥199.00 蓝牙耳机"
        let parsed = try XCTUnwrap(PaymentParser.parse(text))

        XCTAssertEqual(parsed.amount, Decimal(string: "199.00"))
        XCTAssertEqual(parsed.merchant, "蓝牙耳机")
        XCTAssertEqual(parsed.source, .jd)
    }

    func testPinduoduoSample() throws {
        let text = "拼多多支付 ￥9.90 纸巾"
        let parsed = try XCTUnwrap(PaymentParser.parse(text))

        XCTAssertEqual(parsed.amount, Decimal(string: "9.90"))
        XCTAssertEqual(parsed.merchant, "纸巾")
        XCTAssertEqual(parsed.source, .pinduoduo)
    }

    func testGenericSample() throws {
        let text = "今天花了 ￥12.5 买咖啡"
        let parsed = try XCTUnwrap(PaymentParser.parse(text))

        XCTAssertEqual(parsed.amount, Decimal(string: "12.5"))
        XCTAssertEqual(parsed.source, .generic)
        XCTAssertEqual(parsed.confidence, .low)
    }

    func testEmptyTextReturnsNil() {
        XCTAssertNil(PaymentParser.parse(""))
        XCTAssertNil(PaymentParser.parse("   "))
    }

    func testCategorizeDidi() {
        XCTAssertEqual(PaymentParser.categorize(merchant: "滴滴出行", text: ""), "交通")
    }

    func testStructuredPaymentNotification() throws {
        let text = """
        支付成功通知
        消费金额：: 9.9元
        消费门店：: 兴老大·单县羊肉汤（严村里店）
        消费时间：: 2026年06月10日 11:53
        """
        let parsed = try XCTUnwrap(PaymentParser.parse(text))
        XCTAssertEqual(parsed.amount, Decimal(string: "9.9"))
        XCTAssertEqual(parsed.merchant, "兴老大·单县羊肉汤（严村里店）")
        XCTAssertEqual(parsed.category, "餐饮")
    }

    func testWechatPayNotification() throws {
        let text = "你向杭州余杭区良渚陈素红副食品店付款14.00元"
        let parsed = try XCTUnwrap(PaymentParser.parse(text))
        XCTAssertEqual(parsed.amount, Decimal(string: "14.00"))
        XCTAssertTrue(parsed.merchant?.contains("副食品店") == true)
        XCTAssertEqual(parsed.source, .wechat)
    }

    func testWechatBillDetail() throws {
        let text = """
        账单
        杭州余杭区良渚陈素红副食品店
        -14.00
        支付成功
        支付时间
        2026年6月10日 12:11:38
        """
        let parsed = try XCTUnwrap(PaymentParser.parse(text))
        XCTAssertEqual(parsed.amount, Decimal(string: "14"))
        XCTAssertEqual(parsed.merchant, "杭州余杭区良渚陈素红副食品店")
    }

    func testAlipayBillDetail() throws {
        let text = """
        账单详情
        单县羊肉汤
        -9.90
        交易成功
        支付时间
        2026-06-09 20:16:15
        账单分类
        餐饮美食
        """
        let parsed = try XCTUnwrap(PaymentParser.parse(text))
        XCTAssertEqual(parsed.amount, Decimal(string: "9.90"))
        XCTAssertEqual(parsed.merchant, "单县羊肉汤")
        XCTAssertEqual(parsed.category, "餐饮")
    }
}
