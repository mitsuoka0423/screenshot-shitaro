// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenshotShitaro",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "ScreenshotShitaro",
            path: "Sources/ScreenshotShitaro"
        ),
        .testTarget(
            name: "ScreenshotShitaroTests",
            dependencies: ["ScreenshotShitaro"],
            path: "Tests/ScreenshotShitaroTests"
        )
    ]
)
