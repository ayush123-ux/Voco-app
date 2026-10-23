// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoCoNative",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "VoCoNative",
            targets: ["VoCoNative"]
        ),
    ],
    targets: [
        .target(
            name: "VoCoNative",
            path: ".",
            exclude: ["Tests", "Package.swift", "App/VoCoApp.swift", "App/Info.plist"]
        ),
        .testTarget(
            name: "VoCoNativeTests",
            dependencies: ["VoCoNative"],
            path: "Tests"
        )
    ]
)
