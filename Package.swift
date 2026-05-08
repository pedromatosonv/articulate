// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Articulate",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Articulate", targets: ["ArticulateApp"])
    ],
    targets: [
        .executableTarget(
            name: "ArticulateApp",
            path: "Sources/ArticulateApp"
        ),
        .testTarget(
            name: "ArticulateAppTests",
            dependencies: ["ArticulateApp"],
            path: "Tests/ArticulateAppTests"
        )
    ]
)
