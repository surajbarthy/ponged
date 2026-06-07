import SwiftUI

/// Tap each grid cell to hear HRTF position. Use headphones.
struct SpatialDebugView: View {
  @EnvironmentObject private var audio: SpatialAudioEngine
  @Environment(\.dismiss) private var dismiss

  @State private var preset: SoundPreset = .aaow

  private let debugColumns = 3
  private let debugRows = 3

  var body: some View {
    NavigationStack {
      ZStack {
        Color(red: 0.2, green: 0.22, blue: 0.28).ignoresSafeArea()
        ScrollView {
          VStack(spacing: 20) {
            Text("HRTF Spatial Test")
              .font(.title2.bold())
              .foregroundStyle(.white)

            Text("3×3 · fixed 1 m radius · direction only, same volume. Headphones.")
              .font(.subheadline)
              .foregroundStyle(.white.opacity(0.8))
              .multilineTextAlignment(.center)

            Picker("Output", selection: $audio.outputMode) {
              ForEach(SpatialOutputMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
              }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Picker("Sound", selection: $preset) {
              ForEach(SoundPreset.allCases) { p in
                Text(p.displayName).tag(p)
              }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            VStack(spacing: 8) {
              ForEach((0..<debugRows).reversed(), id: \.self) { row in
                HStack(spacing: 8) {
                  ForEach(0..<debugColumns, id: \.self) { col in
                    let cell = GridCell(col: col, row: row)
                    Button(cell.displayLabel(columns: debugColumns, rows: debugRows)) {
                      audio.playOnce(
                        preset: preset,
                        at: cell,
                        gridColumns: debugColumns,
                        gridRows: debugRows
                      )
                    }
                    .font(.caption.bold())
                    .frame(width: 64, height: 52)
                    .background(Color.white.opacity(0.15))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                  }
                }
              }
            }

            VStack(spacing: 4) {
              Text("Position: \(audio.debugPositionLabel)")
                .font(.caption.monospaced())
                .foregroundStyle(.green)
              Text("\(audio.outputMode.rawValue) · loaded: \(audio.loadedPresetCount) · \(audio.engineRunning ? "running" : "stopped")")
                .font(.caption2)
                .foregroundStyle(audio.engineRunning ? .green : .red)
            }

            HStack(spacing: 8) {
              quickButton("Below 0,-1", cell: GridCell(col: 1, row: 0))
              quickButton("Front 0,0", cell: GridCell(col: 1, row: 1))
              quickButton("Above 0,1", cell: GridCell(col: 1, row: 2))
            }
            Text("Same loudness — listen for direction change only")
              .font(.caption2)
              .foregroundStyle(.orange)
          }
          .padding()
        }
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
        }
      }
    }
  }

  private func quickButton(_ title: String, cell: GridCell) -> some View {
    Button(title) {
      audio.playOnce(
        preset: preset,
        at: cell,
        gridColumns: debugColumns,
        gridRows: debugRows
      )
    }
    .font(.caption2)
    .buttonStyle(.bordered)
    .tint(.white)
  }
}
