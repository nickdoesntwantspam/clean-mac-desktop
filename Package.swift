// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "CleanMacDesktop",
  platforms: [.macOS(.v14)],
  products: [
    .library(name: "CleanMacDesktopCore", targets: ["CleanMacDesktopCore"]),
    .executable(name: "CleanMacDesktop", targets: ["CleanMacDesktop"]),
  ],
  targets: [
    .target(name: "CleanMacDesktopCore"),
    .executableTarget(
      name: "CleanMacDesktop",
      dependencies: ["CleanMacDesktopCore"]
    ),
    .testTarget(
      name: "CleanMacDesktopCoreTests",
      dependencies: ["CleanMacDesktopCore"]
    ),
  ]
)
