import XCTest
@testable import GTOAcademy

/// 13×13 矩阵几何：对角对子、右上同花、左下不同花（行业图表习惯）。
final class HandMatrixTests: XCTestCase {
    func testGridShape() {
        XCTAssertEqual(HandMatrix.grid.count, 13)
        for row in HandMatrix.grid {
            XCTAssertEqual(row.count, 13)
        }
        XCTAssertEqual(Set(HandMatrix.grid.flatMap { $0 }).count, 169)
    }

    func testCornersAndDiagonal() {
        XCTAssertEqual(HandMatrix.grid[0][0].notation, "AA")
        XCTAssertEqual(HandMatrix.grid[0][12].notation, "A2s")
        XCTAssertEqual(HandMatrix.grid[12][0].notation, "A2o")
        XCTAssertEqual(HandMatrix.grid[12][12].notation, "22")
        for i in 0..<13 {
            XCTAssertEqual(HandMatrix.grid[i][i].kind, .pair)
        }
    }

    /// 行 3 = J，列 5 = 9：右上同花（4 组合），左下不同花（12 组合）。
    func testKindBySide() {
        XCTAssertEqual(HandMatrix.grid[3][5].notation, "J9s")
        XCTAssertEqual(HandMatrix.grid[3][5].comboCount, 4)
        XCTAssertEqual(HandMatrix.grid[5][3].notation, "J9o")
        XCTAssertEqual(HandMatrix.grid[5][3].comboCount, 12)
    }

    func testMatchesAll169() {
        XCTAssertEqual(Set(HandMatrix.grid.flatMap { $0 }),
                       Set(HandClass.all169))
    }
}
