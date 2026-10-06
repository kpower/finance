/// Backup problems the UI tells apart; anything else (e.g. `DecodingError`) means an unreadable file.
enum BackupError: Error {
  /// The backup's format version is newer than this app supports.
  case unsupportedVersion(Int)
}
