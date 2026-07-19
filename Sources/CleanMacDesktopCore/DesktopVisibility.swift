import Foundation

public enum DesktopVisibility: Equatable, Sendable {
  case visible
  case hidden
}

public enum DesktopVisibilityError: Error, Equatable, LocalizedError, Sendable {
  case unreadablePreference(String)
  case cannotReadPreference
  case cannotChangePreference
  case cannotRefreshFinder

  public var errorDescription: String? {
    switch self {
    case .unreadablePreference(let value):
      return "macOS returned an unfamiliar Desktop setting: \(value)"
    case .cannotReadPreference:
      return "macOS couldn’t read the Desktop setting."
    case .cannotChangePreference:
      return "macOS couldn’t change the Desktop setting."
    case .cannotRefreshFinder:
      return "The setting changed, but Finder couldn’t refresh. Try again or reopen Finder."
    }
  }
}

public struct CommandResult: Equatable, Sendable {
  public let status: Int32
  public let standardOutput: String
  public let standardError: String

  public init(status: Int32, standardOutput: String, standardError: String) {
    self.status = status
    self.standardOutput = standardOutput
    self.standardError = standardError
  }
}

public protocol CommandRunning: Sendable {
  func run(_ executable: String, arguments: [String]) async throws -> CommandResult
}

public struct SystemCommandRunner: CommandRunning {
  public init() {}

  public func run(_ executable: String, arguments: [String]) async throws -> CommandResult {
    try await Task.detached {
      let process = Process()
      let output = Pipe()
      let error = Pipe()
      process.executableURL = URL(fileURLWithPath: executable)
      process.arguments = arguments
      process.standardOutput = output
      process.standardError = error

      try process.run()
      process.waitUntilExit()

      return CommandResult(
        status: process.terminationStatus,
        standardOutput: String(
          decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self),
        standardError: String(
          decoding: error.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
      )
    }.value
  }
}

public struct DesktopVisibilityService<Runner: CommandRunning>: Sendable {
  private let runner: Runner

  public init(runner: Runner) {
    self.runner = runner
  }

  public func currentVisibility() async throws -> DesktopVisibility {
    let result = try await runner.run(
      "/usr/bin/defaults",
      arguments: ["read", "com.apple.WindowManager", "StandardHideDesktopIcons"]
    )

    if result.status != 0 {
      // macOS treats a missing preference as the default: Desktop items are visible.
      if result.standardError.localizedCaseInsensitiveContains("does not exist") {
        return .visible
      }
      throw DesktopVisibilityError.cannotReadPreference
    }

    switch result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
    case "1", "true", "yes": return .hidden
    case "0", "false", "no": return .visible
    case let value: throw DesktopVisibilityError.unreadablePreference(value)
    }
  }

  public func setVisibility(_ visibility: DesktopVisibility) async throws {
    let shouldHide = visibility == .hidden
    let write = try await runner.run(
      "/usr/bin/defaults",
      arguments: [
        "write", "com.apple.WindowManager", "StandardHideDesktopIcons",
        "-bool", shouldHide ? "true" : "false",
      ]
    )
    guard write.status == 0 else {
      throw DesktopVisibilityError.cannotChangePreference
    }

    let refresh = try await runner.run("/usr/bin/killall", arguments: ["Finder"])
    guard refresh.status == 0 else {
      throw DesktopVisibilityError.cannotRefreshFinder
    }
  }
}
