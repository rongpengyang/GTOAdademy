import XCTest
@testable import GTOAcademy

/// 类型工具 VM：输入 → 分类联动、样本门槛、可选项 nil 语义、初值直通与钳制。
/// 范式说明：不写 setUpWithError（nonisolated override 无法给 @MainActor 属性赋值），
/// 测试体内 loadConfig()。
@MainActor
final class PlayerTypeToolViewModelTests: XCTestCase {

    func testManiacInputs() throws {
        let vm = PlayerTypeToolViewModel(config: try loadConfig())
        vm.vpip = 45
        vm.pfr = 35
        vm.includeAF = true
        vm.af = 3.5
        vm.hands = 200
        guard case .classified(.maniac, _) = vm.classification else {
            return XCTFail("应判为 maniac，实际 \(vm.classification)")
        }
    }

    func testInsufficientSample() throws {
        let config = try loadConfig()
        let vm = PlayerTypeToolViewModel(config: config)
        vm.hands = 10
        XCTAssertEqual(vm.classification,
                       .insufficientSample(minimum: config.sampleMin))
    }

    func testTogglesNilOptionalStats() throws {
        let vm = PlayerTypeToolViewModel(config: try loadConfig())
        vm.includeAF = false
        vm.includeFoldToCbet = false
        XCTAssertNil(vm.stats.af)
        XCTAssertNil(vm.stats.foldToCbet)

        vm.includeAF = true
        vm.af = 2.5
        XCTAssertEqual(vm.stats.af, 2.5)
    }

    func testInitialPassthroughAndClamp() throws {
        let initial = PlayerStats(vpip: 48, pfr: 6, af: 0.8, foldToCbet: nil, hands: 200)
        let vm = PlayerTypeToolViewModel(config: try loadConfig(), initial: initial)
        XCTAssertEqual(vm.vpip, 48)
        XCTAssertEqual(vm.pfr, 6)
        XCTAssertTrue(vm.includeAF, "初值带 AF 应自动启用开关")
        XCTAssertFalse(vm.includeFoldToCbet)
        guard case .classified(.passiveFish, _) = vm.classification else {
            return XCTFail("应判为 passive_fish，实际 \(vm.classification)")
        }

        vm.pfr = 60
        vm.clampPFR()
        XCTAssertEqual(vm.pfr, vm.vpip, "clampPFR 应把 PFR 压回 VPIP")
    }

    // MARK: - Helpers

    private func loadConfig() throws -> ClassifierConfig {
        try ContentLoader.load().classifier
    }
}
