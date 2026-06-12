import XCTest
@testable import GTOAcademy

/// 分类器规则 ↔ 题目内容一致性 + 三种结论分支。
final class PlayerClassifierTests: XCTestCase {
    private var library: ContentLibrary!
    private var classifier: PlayerClassifier!

    override func setUpWithError() throws {
        library = try ContentLoader.load()
        classifier = PlayerClassifier(config: library.classifier)
    }

    /// 内容契约：每道玩家类型题的 stats 喂给分类器，必须得到该题答案。
    func testScenarioAnswersMatchClassifier() {
        for scenario in library.playerType {
            let result = classifier.classify(scenario.stats)
            guard case let .classified(type, _) = result else {
                XCTFail("\(scenario.id) 未能分类：\(result)")
                continue
            }
            XCTAssertEqual(type, scenario.correct, scenario.id)
        }
    }

    func testAllSixTypesCoveredByContent() {
        XCTAssertEqual(Set(library.playerType.map(\.correct)).count, 6,
                       "六种玩家类型应各有至少一题")
    }

    func testInsufficientSample() {
        let stats = PlayerStats(vpip: 25, pfr: 20, af: nil, foldToCbet: nil, hands: 10)
        XCTAssertEqual(classifier.classify(stats), .insufficientSample(minimum: 30))
    }

    func testUnclassifiedGap() {
        // vpip 27 超出 TAG 上限（25），pfr 15 不足 LAG 下限（22）→ 中间地带。
        let stats = PlayerStats(vpip: 27, pfr: 15, af: nil, foldToCbet: nil, hands: 100)
        XCTAssertEqual(classifier.classify(stats), .unclassified)
    }

    func testBorderlineFlag() {
        // vpip 24.5 距 TAG 上边界 25 仅 0.5 个百分点（margin 2）→ borderline。
        let near = PlayerStats(vpip: 24.5, pfr: 18, af: nil, foldToCbet: nil, hands: 100)
        XCTAssertEqual(classifier.classify(near), .classified(.tag, borderline: true))

        // vpip 21 / pfr 18.5 距各边界均 ≥ 3 个百分点 → 稳定命中。
        let solid = PlayerStats(vpip: 21, pfr: 18.5, af: nil, foldToCbet: nil, hands: 100)
        XCTAssertEqual(classifier.classify(solid), .classified(.tag, borderline: false))
    }
}
