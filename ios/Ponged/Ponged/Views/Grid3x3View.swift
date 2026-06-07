import SwiftUI

struct Grid3x3View: View {
  var startCell: GridCell?
  var endCell: GridCell?
  var highlightCell: GridCell?
  var pulseEndCell: Bool = false
  var dimEndUntilArrival: Bool = false
  var travelArrived: Bool = true
  var onCellTap: ((GridCell) -> Void)?

  private let rows = MechanicConfig.shared.gridRows
  private let cols = MechanicConfig.shared.gridColumns

  var body: some View {
    VStack(spacing: 8) {
      ForEach((0..<rows).reversed(), id: \.self) { row in
        HStack(spacing: 8) {
          ForEach(0..<cols, id: \.self) { col in
            let cell = GridCell(col: col, row: row)
            cellView(cell)
          }
        }
      }
    }
    .padding()
  }

  @ViewBuilder
  private func cellView(_ cell: GridCell) -> some View {
    let isStart = cell == startCell
    let isEnd = cell == endCell
    let isHighlight = cell == highlightCell
    let endVisible = !dimEndUntilArrival || travelArrived

    Button {
      onCellTap?(cell)
    } label: {
      ZStack {
        RoundedRectangle(cornerRadius: 12)
          .fill(backgroundColor(isStart: isStart, isEnd: isEnd, isHighlight: isHighlight, endVisible: endVisible))
          .overlay {
            if isStart, let end = endCell, isEnd == false {
              EmptyView()
            }
          }
        Text(cell.label)
          .font(.caption.bold())
          .foregroundStyle(.primary)
      }
      .frame(width: 88, height: 72)
      .scaleEffect(pulseEndCell && isEnd && endVisible ? 1.08 : 1)
      .animation(pulseEndCell ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default, value: pulseEndCell)
    }
    .buttonStyle(.plain)
    .disabled(onCellTap == nil)
  }

  private func backgroundColor(isStart: Bool, isEnd: Bool, isHighlight: Bool, endVisible: Bool) -> Color {
    if isStart { return Color.yellow.opacity(0.85) }
    if isEnd {
      return endVisible ? Color.green.opacity(0.75) : Color.gray.opacity(0.35)
    }
    if isHighlight { return Color.pink.opacity(0.5) }
    return Color.white.opacity(0.2)
  }
}
