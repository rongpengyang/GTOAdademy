import XCTest
@testable import GTOAcademy

/// 内容完整性校验：全量解码、引用完整、解释覆盖率 100%、禁用话术零命中。
/// TEST_HOST 指向 App，故 Bundle.main 即 App bundle，可直接读取内容资源。
final class ContentValidationTests: XCTestCase {
    private func loadLibrary() throws -> ContentLibrary {
        try ContentLoader.load(bundle: .main)
    }

    func testLibraryLoads() throws {
        let library = try loadLibrary()
        XCTAssertEqual(library.manifest.schemaVersion, 1)
        XCTAssertEqual(library.trackFiles.count, 4)
        XCTAssertGreaterThanOrEqual(
            library.trackFiles.reduce(0) { $0 + $1.lessons.count }, 30)
        XCTAssertFalse(library.preflop.isEmpty)
        XCTAssertFalse(library.postflop.isEmpty)
        XCTAssertFalse(library.playerType.isEmpty)
        XCTAssertFalse(library.ranges.isEmpty)
        XCTAssertFalse(library.classifier.rules.isEmpty)
        XCTAssertEqual(library.levels.levels.count, 8)
        XCTAssertEqual(library.srs.intervalsDays, [1, 3, 7, 14])
    }

    func testAllContentIDsAreUnique() throws {
        let library = try loadLibrary()
        var ids: [String] = []
        for file in library.trackFiles {
            ids.append(file.track.id)
            ids.append(contentsOf: file.lessons.map(\.id))
            ids.append(contentsOf: file.questions.map(\.id))
        }
        ids.append(contentsOf: library.preflop.map(\.id))
        ids.append(contentsOf: library.postflop.map(\.id))
        ids.append(contentsOf: library.playerType.map(\.id))
        ids.append(contentsOf: library.ranges.map(\.id))
        XCTAssertEqual(ids.count, Set(ids).count, "存在重复内容 id")
    }

    func testQuestionsWellFormed() throws {
        let library = try loadLibrary()
        for file in library.trackFiles {
            for question in file.questions {
                XCTAssertEqual(
                    question.choices.count, question.choiceExplanations.count,
                    "\(question.id): 选项与解释数量不一致")
                XCTAssertTrue(
                    (0..<question.choices.count).contains(question.correctIndex),
                    "\(question.id): correctIndex 越界")
                XCTAssertFalse(question.prompt.zh.isEmpty)
                XCTAssertFalse(question.prompt.en.isEmpty)
                for explanation in question.choiceExplanations {
                    XCTAssertFalse(explanation.zh.isEmpty, "\(question.id): 缺中文选项解释")
                    XCTAssertFalse(explanation.en.isEmpty, "\(question.id): 缺英文选项解释")
                }
            }
        }
    }

    func testLessonStructureAndQuizRefsResolve() throws {
        let library = try loadLibrary()
        let repository = LessonRepository(trackFiles: library.trackFiles)
        for file in library.trackFiles {
            for lesson in file.lessons {
                var hasConcept = false
                var hasMistake = false
                for block in lesson.blocks {
                    if case .concept = block { hasConcept = true }
                    if case .mistake = block { hasMistake = true }
                    if case .unknown = block { XCTFail("\(lesson.id): 含未知 block 类型") }
                }
                XCTAssertTrue(hasConcept, "\(lesson.id): 缺概念块")
                XCTAssertTrue(hasMistake, "\(lesson.id): 缺常见错误块")
                XCTAssertFalse(lesson.quizIDs.isEmpty, "\(lesson.id): 没有训练题")
                for quizID in lesson.quizIDs {
                    XCTAssertNotNil(repository.question(id: quizID),
                                    "\(lesson.id): quizRef \(quizID) 不存在")
                }
            }
        }
    }

    func testPreflopScenariosWellFormed() throws {
        let library = try loadLibrary()
        let lessonIDs = LessonRepository(trackFiles: library.trackFiles).allLessonIDs
        for scenario in library.preflop {
            XCTAssertFalse(scenario.explanation.zh.isEmpty, "\(scenario.id): 缺中文解释")
            XCTAssertFalse(scenario.explanation.en.isEmpty, "\(scenario.id): 缺英文解释")
            XCTAssertNil(scenario.wrongChoices[scenario.correct.rawValue],
                         "\(scenario.id): wrongChoices 不应包含正确答案")
            for acceptable in scenario.acceptable {
                XCTAssertNil(scenario.wrongChoices[acceptable.rawValue],
                             "\(scenario.id): wrongChoices 不应包含可接受答案")
            }
            for (_, text) in scenario.wrongChoices {
                XCTAssertFalse(text.zh.isEmpty)
                XCTAssertFalse(text.en.isEmpty)
            }
            if let reference = scenario.lessonRef {
                XCTAssertTrue(lessonIDs.contains(reference),
                              "\(scenario.id): lessonRef \(reference) 不存在")
            }
            XCTAssertTrue((1...3).contains(scenario.difficulty))
            if scenario.kind == .rfi {
                XCTAssertTrue(scenario.facing.isEmpty, "\(scenario.id): RFI 题不应有前置动作")
            } else {
                XCTAssertFalse(scenario.facing.isEmpty, "\(scenario.id): 非 RFI 题缺前置动作")
            }
        }
    }

    func testPostflopScenariosWellFormed() throws {
        let library = try loadLibrary()
        for scenario in library.postflop {
            XCTAssertNotNil(Board(cards: scenario.board), "\(scenario.id): 公共牌非法")
            XCTAssertFalse(scenario.explanation.zh.isEmpty)
            XCTAssertFalse(scenario.explanation.en.isEmpty)
            XCTAssertFalse(scenario.reasonTags.isEmpty, "\(scenario.id): 缺理由标签")
            XCTAssertFalse(scenario.history.isEmpty, "\(scenario.id): 缺行动历史")
            XCTAssertNil(scenario.wrongChoices[scenario.correct.key],
                         "\(scenario.id): wrongChoices 不应包含正确答案")
            for acceptable in scenario.acceptable {
                XCTAssertNil(scenario.wrongChoices[acceptable.key],
                             "\(scenario.id): wrongChoices 不应包含可接受答案")
            }
            XCTAssertGreaterThan(scenario.potBB, 0)
            XCTAssertGreaterThan(scenario.effStackBB, 0)
        }
    }

    func testPlayerTypeScenariosWellFormed() throws {
        let library = try loadLibrary()
        for scenario in library.playerType {
            XCTAssertFalse(scenario.explanation.zh.isEmpty)
            XCTAssertFalse(scenario.explanation.en.isEmpty)
            XCTAssertGreaterThan(scenario.stats.hands, 0)
        }
    }

    /// PRD 内容配额钉死：翻后 ≥45（翻牌 ≥30、转/河各 ≥7，AC-E1）、类型 ≥25（AC-D2）。
    func testScenarioQuotasMeetPRD() throws {
        let library = try loadLibrary()
        let flop = library.postflop.filter { $0.board.count == 3 }.count
        let turn = library.postflop.filter { $0.board.count == 4 }.count
        let river = library.postflop.filter { $0.board.count == 5 }.count
        XCTAssertGreaterThanOrEqual(flop, 30, "翻牌街精编不足（AC-E1）")
        XCTAssertGreaterThanOrEqual(turn, 7, "转牌街精编不足（AC-E1）")
        XCTAssertGreaterThanOrEqual(river, 7, "河牌街精编不足（AC-E1）")
        XCTAssertGreaterThanOrEqual(library.postflop.count, 45, "翻后总量不足（AC-E1）")
        XCTAssertGreaterThanOrEqual(library.preflop.count, 90, "翻前精编不足（PRD §215）")
        XCTAssertGreaterThanOrEqual(library.playerType.count, 25, "类型题不足（AC-D2）")
    }

    func testRangePercentSanity() throws {
        let library = try loadLibrary()
        let utg = try XCTUnwrap(library.ranges.first { $0.id == "rfi-utg-100bb" })
        XCTAssertTrue((12.0...16.0).contains(utg.percentOfDeck),
                      "UTG RFI 占比异常: \(utg.percentOfDeck)%")
        let btn = try XCTUnwrap(library.ranges.first { $0.id == "rfi-btn-100bb" })
        XCTAssertTrue((38.0...46.0).contains(btn.percentOfDeck),
                      "BTN RFI 占比异常: \(btn.percentOfDeck)%")
        for chart in library.ranges {
            XCTAssertFalse(chart.cells.isEmpty, "\(chart.id): 空范围")
            XCTAssertFalse(chart.source.isEmpty, "\(chart.id): 缺 source 标注")
        }
    }

    func testNoBannedPhrasesInContent() throws {
        let library = try loadLibrary()
        var texts: [String] = []

        func collect(_ localized: LocalizedText) {
            texts.append(localized.zh)
            texts.append(localized.en)
        }

        for file in library.trackFiles {
            collect(file.track.title)
            if let subtitle = file.track.subtitle { collect(subtitle) }
            for lesson in file.lessons {
                collect(lesson.title)
                for block in lesson.blocks {
                    switch block {
                    case .concept(let text), .example(let text),
                         .mistake(let text), .tip(let text):
                        collect(text)
                    case .quizRef, .unknown:
                        break
                    }
                }
            }
            for question in file.questions {
                collect(question.prompt)
                collect(question.objective)
                question.choices.forEach(collect)
                question.choiceExplanations.forEach(collect)
            }
        }
        for scenario in library.preflop {
            collect(scenario.explanation)
            collect(scenario.objective)
            scenario.wrongChoices.values.forEach(collect)
        }
        for scenario in library.postflop {
            collect(scenario.explanation)
            collect(scenario.objective)
            scenario.history.forEach(collect)
            scenario.wrongChoices.values.forEach(collect)
        }
        for scenario in library.playerType {
            collect(scenario.explanation)
            collect(scenario.objective)
        }
        for chart in library.ranges {
            collect(chart.name)
        }

        for phrase in library.banned.phrases {
            let needle = phrase.lowercased()
            for text in texts {
                XCTAssertFalse(text.lowercased().contains(needle),
                               "命中禁用话术「\(phrase)」: \(text.prefix(50))")
            }
        }
    }
}
