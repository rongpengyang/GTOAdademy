import Foundation

/// 13×13 起手牌矩阵的几何模型。
/// 行 = 第一张牌（A→2 降序），列 = 第二张牌（A→2 降序）：
/// 对角线为对子，右上三角为同花（s），左下三角为不同花（o）——与行业图表习惯一致。
/// 纯数据：RangeMatrixView 渲染与单元测试共用。
enum HandMatrix {
    /// A → 2 的 13 个 rank。
    static let ranksDescending: [Rank] = Rank.allCases.sorted(by: >)

    /// grid[row][col]：row == col 对子；row < col 同花；row > col 不同花。
    static let grid: [[HandClass]] = {
        let byNotation = Dictionary(
            uniqueKeysWithValues: HandClass.all169.map { ($0.notation, $0) })
        return (0..<13).map { row in
            (0..<13).map { col in
                byNotation[notation(row: row, col: col)]!
            }
        }
    }()

    /// 坐标 → 记法：(0,0)→AA · (0,1)→AKs · (1,0)→AKo · (12,12)→22。
    /// 记法恒以高牌在前：不同花格（row > col）的高牌取列 rank。
    static func notation(row: Int, col: Int) -> String {
        let rowLetter = ranksDescending[row].letter
        let colLetter = ranksDescending[col].letter
        if row == col { return rowLetter + rowLetter }
        return row < col
            ? rowLetter + colLetter + "s"
            : colLetter + rowLetter + "o"
    }
}
