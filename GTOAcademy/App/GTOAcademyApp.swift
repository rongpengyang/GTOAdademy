import SwiftUI
import SwiftData

@main
struct GTOAcademyApp: App {
    @State private var bootstrap = AppBootstrap()

    var body: some Scene {
        WindowGroup {
            Group {
                switch bootstrap.state {
                case .loading:
                    LaunchLoadingView()
                case .failed(let message):
                    ContentErrorView(message: message)
                case .ready(let dependencies):
                    AppRootView()
                        .environment(dependencies)
                }
            }
            .task { await bootstrap.loadIfNeeded() }
        }
        .modelContainer(for: [
            UserProgress.self,
            DrillRecord.self,
            MistakeReviewItem.self,
            AppSettings.self,
        ])
    }
}

/// 启动加载页。
struct LaunchLoadingView: View {
    var body: some View {
        ZStack {
            Theme.inkBackground.ignoresSafeArea()
            VStack(spacing: Spacing.s16) {
                ProgressView()
                Text(L10n.loading)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

/// 内容损坏时的显式错误页。
struct ContentErrorView: View {
    let message: String

    var body: some View {
        ZStack {
            Theme.inkBackground.ignoresSafeArea()
            VStack(spacing: Spacing.s12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.danger)
                Text(L10n.contentErrorTitle)
                    .font(Typo.title)
                    .foregroundStyle(Theme.textPrimary)
                Text(message)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.s24)
            }
        }
    }
}
