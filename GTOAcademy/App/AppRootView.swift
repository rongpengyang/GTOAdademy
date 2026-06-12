import SwiftUI
import SwiftData

/// 5-Tab 根视图。主题与触感设置在这里统一生效。
struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsRecords: [AppSettings]

    var body: some View {
        TabView {
            Tab {
                NavigationStack { HomeDashboardView() }
            } label: {
                Label(L10n.tabHome, systemImage: "house.fill")
            }

            Tab {
                NavigationStack { LearnPathView() }
            } label: {
                Label(L10n.tabLearn, systemImage: "book.fill")
            }

            Tab {
                NavigationStack { DrillHomeView() }
            } label: {
                Label(L10n.tabDrill, systemImage: "target")
            }

            Tab {
                NavigationStack { ToolsHomeView() }
            } label: {
                Label(L10n.tabTools, systemImage: "square.grid.3x3.fill")
            }

            Tab {
                NavigationStack { ProfileView() }
            } label: {
                Label(L10n.tabProfile, systemImage: "person.crop.circle.fill")
            }
        }
        .tint(Theme.feltAccent)
        .preferredColorScheme(
            SettingsStore.colorScheme(for: settingsRecords.first?.preferredTheme ?? "system"))
        .onAppear {
            SettingsStore.applyHaptics(SettingsStore.settings(in: modelContext))
        }
        .onChange(of: settingsRecords.first?.hapticsEnabled) {
            if let settings = settingsRecords.first {
                SettingsStore.applyHaptics(settings)
            }
        }
    }
}

#Preview {
    let library = try! ContentLoader.load()
    return AppRootView()
        .environment(AppDependencies(content: library))
        .modelContainer(
            for: [UserProgress.self, DrillRecord.self, MistakeReviewItem.self, AppSettings.self],
            inMemory: true)
}
