// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenshotShitaro",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ScreenshotShitaro",
            path: "Sources/ScreenshotShitaro",
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "ScreenshotShitaroTests",
            dependencies: ["ScreenshotShitaro"],
            path: "Tests/ScreenshotShitaroTests"
        )
    ]
)
