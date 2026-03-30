// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "KidsLock",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .executable(
            name: "KidsLock",
            targets: ["KidsLock"]
        )
    ],
    targets: [
        .executableTarget(
            name: "KidsLock",
            path: "Sources"
        )
    ]
)
