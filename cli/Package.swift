// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "easykey",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "easykey",
            targets: ["easykey"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "easykey",
            dependencies: [],
            path: "Sources/easykey"
        ),
    ]
)
