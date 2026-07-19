import AppKit
import CleanMacDesktopCore
import SwiftUI

@main
struct CleanMacDesktopApp: App {
  @State private var model = DesktopMenuModel()

  init() {
    NSApplication.shared.setActivationPolicy(.accessory)
  }

  var body: some Scene {
    MenuBarExtra {
      DesktopMenu(model: model)
    } label: {
      Label("Clean Mac Desktop", systemImage: model.menuBarSymbol)
    }
    .menuBarExtraStyle(.menu)
  }
}

@MainActor
@Observable
final class DesktopMenuModel {
  enum State: Equatable {
    case loading
    case ready(DesktopVisibility)
    case applying(DesktopVisibility)
    case failed(message: String, lastKnown: DesktopVisibility?)
  }

  private let service = DesktopVisibilityService(runner: SystemCommandRunner())
  private var pollTask: Task<Void, Never>?
  var state: State = .loading

  init() {
    refresh()
    pollTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(2))
        await self?.refreshSilently()
      }
    }
  }

  var menuBarSymbol: String {
    switch state {
    case .ready(.hidden), .applying(.hidden): "rectangle.dashed"
    case .failed(_, .hidden): "rectangle.dashed"
    default: "rectangle.grid.2x2"
    }
  }

  var currentVisibility: DesktopVisibility? {
    switch state {
    case .ready(let visibility), .applying(let visibility): visibility
    case .failed(_, let lastKnown): lastKnown
    case .loading: nil
    }
  }

  var isBusy: Bool {
    if case .applying = state { return true }
    return false
  }

  func toggle() {
    guard let currentVisibility, !isBusy else { return }
    let requested: DesktopVisibility = currentVisibility == .visible ? .hidden : .visible
    state = .applying(requested)

    Task {
      do {
        try await service.setVisibility(requested)
        state = .ready(requested)
      } catch {
        let actualVisibility = try? await service.currentVisibility()
        state = .failed(
          message: error.localizedDescription,
          lastKnown: actualVisibility ?? currentVisibility
        )
      }
    }
  }

  func refresh() {
    Task {
      do {
        state = .ready(try await service.currentVisibility())
      } catch {
        state = .failed(message: error.localizedDescription, lastKnown: currentVisibility)
      }
    }
  }

  private func refreshSilently() async {
    guard !isBusy else { return }
    if let visibility = try? await service.currentVisibility(), visibility != currentVisibility {
      state = .ready(visibility)
    }
  }
}

private struct DesktopMenu: View {
  let model: DesktopMenuModel

  var body: some View {
    Section {
      Button(action: model.toggle) {
        Label(primaryActionTitle, systemImage: primaryActionSymbol)
      }
      .disabled(model.currentVisibility == nil || model.isBusy)
    } header: {
      Text(statusTitle)
    }

    if case .failed(let message, _) = model.state {
      Section("Couldn’t change the Desktop") {
        Text(message)
        Button("Try Again", action: model.refresh)
      }
    }

    Section {
      Button("Desktop & Dock Settings") {
        guard
          let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension")
        else { return }
        NSWorkspace.shared.open(url)
      }
    }

    Section {
      Button("Quit Clean Mac Desktop") {
        NSApplication.shared.terminate(nil)
      }
      .keyboardShortcut("q")
    }
  }

  private var statusTitle: String {
    switch model.state {
    case .loading: "Checking Desktop…"
    case .ready(.visible): "Desktop items are visible"
    case .ready(.hidden): "Desktop items are hidden"
    case .applying(.visible): "Showing Desktop items…"
    case .applying(.hidden): "Hiding Desktop items…"
    case .failed: "Desktop status unavailable"
    }
  }

  private var primaryActionTitle: String {
    if model.currentVisibility == nil { return "Checking…" }
    if model.isBusy { return "Applying…" }
    return model.currentVisibility == .hidden ? "Show Desktop Items" : "Hide Desktop Items"
  }

  private var primaryActionSymbol: String {
    if model.currentVisibility == nil { return "hourglass" }
    return model.currentVisibility == .hidden ? "eye" : "eye.slash"
  }
}
