import SwiftData

/// Values of something that is in the store, with its identity there.
struct Stored<Values>: Identifiable {
  let id: PersistentIdentifier
  let values: Values
}
