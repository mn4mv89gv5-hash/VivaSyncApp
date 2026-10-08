// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VivaSyncApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "VivaSyncApp",
            targets: ["VivaSyncApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "VivaSyncApp",
            path: "Sources/VivaSyncApp"
        )
    ]
)
