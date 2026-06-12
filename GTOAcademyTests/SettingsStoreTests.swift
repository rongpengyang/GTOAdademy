import XCTest
import SwiftData
import SwiftUI
@testable import GTOAcademy

/// 设置单例与映射（内存容器，不落盘）。
@MainActor
final class SettingsStoreTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: UserProgress.self, DrillRecord.self,
                 MistakeReviewItem.self, AppSettings.self,
            configurations: configuration)
        return ModelContext(container)
    }

    func testSettingsSingleton() throws {
        let context = try makeContext()
        let first = SettingsStore.settings(in: context)
        let second = SettingsStore.settings(in: context)

        XCTAssertEqual(try context.fetch(FetchDescriptor<AppSettings>()).count, 1)
        XCTAssertEqual(first.persistentModelID, second.persistentModelID)
    }

    func testDefaults() throws {
        let context = try makeContext()
        let settings = SettingsStore.settings(in: context)

        XCTAssertTrue(settings.fourColorDeck)
        XCTAssertTrue(settings.hapticsEnabled)
        XCTAssertEqual(settings.preferredTheme, "system")
        XCTAssertNil(settings.classifierOverridesJSON)
    }

    func testColorSchemeMapping() {
        XCTAssertEqual(SettingsStore.colorScheme(for: "dark"), .dark)
        XCTAssertEqual(SettingsStore.colorScheme(for: "light"), .light)
        XCTAssertNil(SettingsStore.colorScheme(for: "system"))
        XCTAssertNil(SettingsStore.colorScheme(for: "neon"))
    }

    func testApplyHapticsSyncsGate() throws {
        let context = try makeContext()
        let settings = SettingsStore.settings(in: context)

        settings.hapticsEnabled = false
        SettingsStore.applyHaptics(settings)
        XCTAssertFalse(Haptics.isEnabled)

        settings.hapticsEnabled = true
        SettingsStore.applyHaptics(settings)
        XCTAssertTrue(Haptics.isEnabled)
    }
}
