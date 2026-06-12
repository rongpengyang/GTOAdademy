import Foundation

/// 加载并校验后的全部只读内容。启动时构建一次，Sendable 可自由跨任务。
struct ContentLibrary: Sendable {
    let manifest: ContentManifest
    let trackFiles: [LessonTrackFile]
    let preflop: [PreflopScenario]
    let postflop: [PostflopScenario]
    let playerType: [PlayerTypeScenario]
    let ranges: [RangeChart]
    let classifier: ClassifierConfig
    let levels: LevelConfig
    let srs: SRSConfig
    let banned: BannedPhrases
}

enum ContentLoadError: Error, CustomStringConvertible {
    case missingResource(String)
    case decoding(String, Error)
    case rangeBuild(String, Error)

    var description: String {
        switch self {
        case .missingResource(let name):
            "Missing content resource: \(name).json"
        case .decoding(let name, let error):
            "Failed to decode \(name).json — \(error)"
        case .rangeBuild(let id, let error):
            "Failed to build range chart \(id) — \(error)"
        }
    }
}

/// 内容管线入口：manifest 驱动，全部文件解码失败即整体失败（不允许半残运行）。
enum ContentLoader {
    /// v1 内容为 KB 级，同步解码即可；内容增长后移入后台 Task。
    static func load(bundle: Bundle = .main) throws -> ContentLibrary {
        let manifest: ContentManifest = try decode("manifest", bundle: bundle)

        let trackFiles: [LessonTrackFile] = try manifest.lessonFiles.map {
            try decode($0, bundle: bundle)
        }

        let preflopFile: ScenarioFile<PreflopScenario> =
            try decode(manifest.scenarioFiles.preflop, bundle: bundle)
        let postflopFile: ScenarioFile<PostflopScenario> =
            try decode(manifest.scenarioFiles.postflop, bundle: bundle)
        let playerTypeFile: ScenarioFile<PlayerTypeScenario> =
            try decode(manifest.scenarioFiles.playerType, bundle: bundle)

        let ranges: [RangeChart] = try manifest.rangeFiles.map { name in
            let file: RangeChartFile = try decode(name, bundle: bundle)
            do {
                return try chart(from: file)
            } catch {
                throw ContentLoadError.rangeBuild(file.id, error)
            }
        }

        let classifier: ClassifierConfig = try decode("classifier", bundle: bundle)
        let levels: LevelConfig = try decode("levels", bundle: bundle)
        let srs: SRSConfig = try decode("srs", bundle: bundle)
        let banned: BannedPhrases = try decode("banned_phrases", bundle: bundle)

        return ContentLibrary(
            manifest: manifest,
            trackFiles: trackFiles,
            preflop: preflopFile.scenarios,
            postflop: postflopFile.scenarios,
            playerType: playerTypeFile.scenarios,
            ranges: ranges,
            classifier: classifier,
            levels: levels,
            srs: srs,
            banned: banned)
    }

    /// RangeChartFile → RangeChart：notation 经 RangeParser 展开，显式 cells 覆盖同名格。
    static func chart(from file: RangeChartFile) throws -> RangeChart {
        var cells: [HandClass: [ActionWeight]] = [:]
        if let notation = file.notation {
            for (hand, weight) in try RangeParser.parse(notation) {
                cells[hand] = [ActionWeight(action: file.action, weight: weight)]
            }
        }
        if let explicit = file.cells {
            for cell in explicit {
                cells[cell.hand] = cell.actions
            }
        }
        return RangeChart(
            id: file.id,
            name: file.name,
            position: file.position,
            stackBB: file.stack,
            action: file.action,
            source: file.source,
            cells: cells)
    }

    // MARK: - Helpers

    private static func decode<T: Decodable>(_ name: String, bundle: Bundle) throws -> T {
        guard let url = url(for: name, in: bundle) else {
            throw ContentLoadError.missingResource(name)
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ContentLoadError.decoding(name, error)
        }
    }

    /// Xcode group 方式（XcodeGen 默认）会把资源平铺到 bundle 根；
    /// folder reference 方式则保留子目录。两种布局都兜底。
    private static func url(for name: String, in bundle: Bundle) -> URL? {
        if let url = bundle.url(forResource: name, withExtension: "json") {
            return url
        }
        let subdirectories = [
            "Content", "Content/config", "Content/lessons",
            "Content/scenarios", "Content/ranges",
        ]
        for sub in subdirectories {
            if let url = bundle.url(forResource: name, withExtension: "json", subdirectory: sub) {
                return url
            }
        }
        return nil
    }
}
