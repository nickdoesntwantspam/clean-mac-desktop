import Foundation
import Testing

@testable import CleanMacDesktopCore

private actor StubRunner: CommandRunning {
  private var results: [CommandResult]
  private(set) var invocations: [(String, [String])] = []

  init(_ results: [CommandResult]) {
    self.results = results
  }

  func run(_ executable: String, arguments: [String]) async throws -> CommandResult {
    invocations.append((executable, arguments))
    return results.removeFirst()
  }
}

@Suite("Desktop visibility service")
struct DesktopVisibilityServiceTests {
  @Test(arguments: ["1", "true", "YES"])
  func parsesHiddenValues(_ value: String) async throws {
    let runner = StubRunner([.init(status: 0, standardOutput: "\(value)\n", standardError: "")])
    let service = DesktopVisibilityService(runner: runner)
    #expect(try await service.currentVisibility() == .hidden)
  }

  @Test(arguments: ["0", "false", "no"])
  func parsesVisibleValues(_ value: String) async throws {
    let runner = StubRunner([.init(status: 0, standardOutput: " \(value) \n", standardError: "")])
    let service = DesktopVisibilityService(runner: runner)
    #expect(try await service.currentVisibility() == .visible)
  }

  @Test func missingPreferenceUsesMacOSDefault() async throws {
    let runner = StubRunner([
      .init(
        status: 1,
        standardOutput: "",
        standardError: "The domain/default pair does not exist"
      )
    ])
    let service = DesktopVisibilityService(runner: runner)
    #expect(try await service.currentVisibility() == .visible)
  }

  @Test func rejectsUnknownValues() async {
    let runner = StubRunner([.init(status: 0, standardOutput: "sometimes", standardError: "")])
    let service = DesktopVisibilityService(runner: runner)
    await #expect(throws: DesktopVisibilityError.unreadablePreference("sometimes")) {
      try await service.currentVisibility()
    }
  }

  @Test func hidingWritesPreferenceThenRefreshesFinder() async throws {
    let runner = StubRunner([
      .init(status: 0, standardOutput: "", standardError: ""),
      .init(status: 0, standardOutput: "", standardError: ""),
    ])
    let service = DesktopVisibilityService(runner: runner)
    try await service.setVisibility(.hidden)

    let invocations = await runner.invocations
    #expect(invocations.count == 2)
    #expect(invocations[0].0 == "/usr/bin/defaults")
    #expect(invocations[0].1.suffix(2) == ["-bool", "true"])
    #expect(invocations[1].0 == "/usr/bin/killall")
    #expect(invocations[1].1 == ["Finder"])
  }

  @Test func showingWritesFalse() async throws {
    let runner = StubRunner([
      .init(status: 0, standardOutput: "", standardError: ""),
      .init(status: 0, standardOutput: "", standardError: ""),
    ])
    let service = DesktopVisibilityService(runner: runner)
    try await service.setVisibility(.visible)
    let invocations = await runner.invocations
    #expect(invocations[0].1.suffix(2) == ["-bool", "false"])
  }

  @Test func writeFailureDoesNotRestartFinder() async {
    let runner = StubRunner([.init(status: 7, standardOutput: "", standardError: "denied")])
    let service = DesktopVisibilityService(runner: runner)
    await #expect(throws: DesktopVisibilityError.cannotChangePreference) {
      try await service.setVisibility(.hidden)
    }
    #expect(await runner.invocations.count == 1)
  }

  @Test func readFailureUsesPlainLanguageError() async {
    let runner = StubRunner([.init(status: 7, standardOutput: "", standardError: "internal detail")]
    )
    let service = DesktopVisibilityService(runner: runner)
    await #expect(throws: DesktopVisibilityError.cannotReadPreference) {
      try await service.currentVisibility()
    }
  }

  @Test func finderRefreshFailureIsDistinctFromWriteFailure() async {
    let runner = StubRunner([
      .init(status: 0, standardOutput: "", standardError: ""),
      .init(status: 1, standardOutput: "", standardError: "internal detail"),
    ])
    let service = DesktopVisibilityService(runner: runner)
    await #expect(throws: DesktopVisibilityError.cannotRefreshFinder) {
      try await service.setVisibility(.hidden)
    }
  }
}
