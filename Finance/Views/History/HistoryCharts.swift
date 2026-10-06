import Charts
import Foundation
import SwiftUI

/// Total over time, converted to each currency: one chart per currency, hover synced across them.
struct HistoryCharts: View {
  /// Rows in any order.
  let rows: [HistoryRow]

  @State private var hoveredDate: Date?

  var body: some View {
    let sorted = rows.sorted { $0.date < $1.date }
    HStack(spacing: 16) {
      TotalChart(title: .historyChartTotalRubTitle, points: sorted.map { ($0, $0.totalRUB) }, hoveredDate: $hoveredDate)
      TotalChart(title: .historyChartTotalUsdTitle, points: sorted.compactMap { r in r.totalUSD.map { (r, $0) } }, hoveredDate: $hoveredDate)
      TotalChart(title: .historyChartTotalEurTitle, points: sorted.compactMap { r in r.totalEUR.map { (r, $0) } }, hoveredDate: $hoveredDate)
    }
    .padding(16)
  }
}

private struct TotalChart: View {
  let title: LocalizedStringResource
  let points: [(row: HistoryRow, value: Double)]
  @Binding var hoveredDate: Date?

  /// Point closest to the hovered date.
  private var hovered: (row: HistoryRow, value: Double)? {
    guard let hoveredDate else { return nil }
    return points.min {
      abs($0.row.date.timeIntervalSince(hoveredDate)) < abs($1.row.date.timeIntervalSince(hoveredDate))
    }
  }

  /// Value range padded so a flat or single-point series doesn't collapse the axis.
  private var yDomain: ClosedRange<Double> {
    let values = points.map(\.value)
    guard let low = values.min(), let high = values.max() else { return 0...1 }
    let pad = Swift.max((high - low) * 0.1, Swift.abs(high) * 0.05, 1)
    return (low - pad)...(high + pad)
  }

  /// Ticks only at dates that have data (at most 4), so labels never repeat.
  private var xTicks: [Date] {
    let dates = points.map(\.row.date)
    guard dates.count > 4 else { return dates }
    let last = dates.count - 1
    return [0, last / 3, 2 * last / 3, last].map { dates[$0] }
  }

  var body: some View {
    let dateLabel = String(localized: .historyChartDateAxisLabel)
    let valueLabel = String(localized: title)
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.headline)
      Chart {
        ForEach(points, id: \.row.id) { point in
          LineMark(x: .value(dateLabel, point.row.date, unit: .day), y: .value(valueLabel, point.value))
            .lineStyle(StrokeStyle(lineWidth: 2))
          PointMark(x: .value(dateLabel, point.row.date, unit: .day), y: .value(valueLabel, point.value))
            .symbolSize(40)
        }
        if let hovered {
          RuleMark(x: .value(dateLabel, hovered.row.date, unit: .day))
            .foregroundStyle(.secondary.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1))
            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
              tooltip(hovered)
            }
        }
      }
      .chartXSelection(value: $hoveredDate)
      .chartYScale(domain: yDomain)
      .chartYAxis {
        AxisMarks(values: .automatic(desiredCount: 4)) { value in
          AxisGridLine().foregroundStyle(.quaternary)
          AxisValueLabel(anchor: .leading) {
            if let number = value.as(Double.self) {
              Text(number.formatted(.number.notation(.compactName).precision(.significantDigits(1...4))))
            }
          }
        }
      }
      .chartXAxis {
        AxisMarks(values: xTicks) { _ in
          AxisGridLine().foregroundStyle(.quaternary)
          AxisValueLabel(format: .dateTime.day(.twoDigits).month(.twoDigits).year(.twoDigits), anchor: .top)
        }
      }
      .frame(minHeight: 140)
    }
    .frame(maxWidth: .infinity)
  }

  private func tooltip(_ point: (row: HistoryRow, value: Double)) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(Fmt.date(point.row.date)).font(.caption).foregroundStyle(.secondary)
      Text(Fmt.money(point.value)).font(.callout.weight(.semibold)).monospacedDigit()
      if point.row.isSummaryOnly {
        Text(.historyChartArchiveEntryLabel).font(.caption2).foregroundStyle(.secondary)
      }
    }
    .padding(6)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
  }
}
