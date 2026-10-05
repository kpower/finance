import SwiftData
import SwiftUI

/// Read-only view of the deposits as they were on the snapshot's date.
struct SnapshotDetailView: View {
  let snapshot: Snapshot

  private var rates: Rates { snapshot.rates }
  private var items: [DepositRecord] { snapshot.items }
  private var sumRUB: Double { items.reduce(0) { $0 + ($1.amountRUB ?? 0) } }
  private var sumUSD: Double { items.reduce(0) { $0 + ($1.amountUSD ?? 0) } }
  private var sumEUR: Double { items.reduce(0) { $0 + ($1.amountEUR ?? 0) } }
  private var total: Double { items.reduce(0) { $0 + $1.totalRUB(at: rates) } }

  var body: some View {
    VStack(spacing: 0) {
      Table(items) {
        TableColumn("Название") { Text($0.name) }
          .width(min: 120, ideal: 180)
        TableColumn("Банк") { Text($0.bank) }
          .width(min: 90, ideal: 130)
        TableColumn("₽") { money($0.amountRUB) }
          .width(min: 100, ideal: 115)
          .alignment(.trailing)
        TableColumn("$") { money($0.amountUSD) }
          .width(min: 90, ideal: 105)
          .alignment(.trailing)
        TableColumn("€") { money($0.amountEUR) }
          .width(min: 90, ideal: 105)
          .alignment(.trailing)
        TableColumn("Итого ₽") {
          Text($0.isEmpty ? "" : Fmt.money($0.totalRUB(at: rates)))
            .monospacedDigit().fontWeight(.semibold)
        }
        .width(min: 110, ideal: 125)
        .alignment(.trailing)
        TableColumn("%") { item in
          Text(item.interestRate.map { $0.formatted(.number.precision(.fractionLength(0...2)).locale(Fmt.ruLocale)) } ?? "")
            .monospacedDigit()
        }
        .width(min: 50, ideal: 60)
        .alignment(.trailing)
        TableColumn("Срок, мес.") { Text($0.termMonths.map(String.init) ?? "").monospacedDigit() }
          .width(min: 70, ideal: 80)
          .alignment(.trailing)
        TableColumn("Открыт") { Text(Fmt.date($0.openDate)).monospacedDigit() }
          .width(min: 80, ideal: 90)
        TableColumn("Закрытие") { Text(Fmt.date($0.closeDate)).monospacedDigit() }
          .width(min: 80, ideal: 90)
      }
      Divider()
      footer
    }
    .navigationTitle("Вклады на \(Fmt.date(snapshot.date))")
  }

  private func money(_ value: Double?) -> some View {
    Text(Fmt.money(value)).monospacedDigit()
  }

  private var footer: some View {
    HStack(alignment: .firstTextBaseline, spacing: 24) {
      VStack(alignment: .leading, spacing: 2) {
        Text("Курсы на \(Fmt.date(snapshot.date))").font(.caption).foregroundStyle(.secondary)
        Text("$ \(Fmt.rate(rates.usd))   € \(Fmt.rate(rates.eur))").monospacedDigit()
      }
      Spacer()
      sum("Σ ₽", sumRUB)
      sum("Σ $", sumUSD)
      sum("Σ €", sumEUR)
      VStack(alignment: .trailing, spacing: 2) {
        Text("Итого в ₽").font(.caption).foregroundStyle(.secondary)
        Text(Fmt.money(total)).font(.title3.weight(.semibold)).monospacedDigit()
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(.bar)
  }

  private func sum(_ title: String, _ value: Double) -> some View {
    VStack(alignment: .trailing, spacing: 2) {
      Text(title).font(.caption).foregroundStyle(.secondary)
      Text(Fmt.money(value)).monospacedDigit()
    }
  }
}

#Preview {
  let container = try! ModelContainer(
    for: Snapshot.self, Deposit.self, RateRecord.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  PreviewData.seed(container.mainContext)
  let snapshot = (try? container.mainContext.fetch(FetchDescriptor<Snapshot>(sortBy: [SortDescriptor(\.date)])))?.last
  return NavigationStack {
    if let snapshot { SnapshotDetailView(snapshot: snapshot) }
  }
  .modelContainer(container)
  .frame(width: 1100, height: 400)
}
