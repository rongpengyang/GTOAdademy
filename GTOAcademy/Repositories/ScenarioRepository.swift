import Foundation

/// 训练场景查询仓库（只读，Sendable）。
struct ScenarioRepository: Sendable {
    let preflop: [PreflopScenario]
    let postflop: [PostflopScenario]
    let playerType: [PlayerTypeScenario]

    private let preflopByID: [String: PreflopScenario]
    private let postflopByID: [String: PostflopScenario]
    private let playerTypeByID: [String: PlayerTypeScenario]

    init(preflop: [PreflopScenario],
         postflop: [PostflopScenario],
         playerType: [PlayerTypeScenario]) {
        self.preflop = preflop
        self.postflop = postflop
        self.playerType = playerType
        self.preflopByID = Dictionary(preflop.map { ($0.id, $0) }) { first, _ in first }
        self.postflopByID = Dictionary(postflop.map { ($0.id, $0) }) { first, _ in first }
        self.playerTypeByID = Dictionary(playerType.map { ($0.id, $0) }) { first, _ in first }
    }

    func preflop(id: String) -> PreflopScenario? { preflopByID[id] }
    func postflop(id: String) -> PostflopScenario? { postflopByID[id] }
    func playerType(id: String) -> PlayerTypeScenario? { playerTypeByID[id] }

    func preflop(kind: PreflopScenarioKind) -> [PreflopScenario] {
        preflop.filter { $0.kind == kind }
    }

    var totalCount: Int { preflop.count + postflop.count + playerType.count }
}
