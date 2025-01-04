// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "zip",
    products: [
        .library(name: "Zip", targets: ["Zip"]),
    ],
    targets: [
        .target(name: "Zip", dependencies: ["Miniz"]),
        .target(name: "Miniz", path: "Sources/miniz", publicHeadersPath: "."),
        .testTarget(name: "Tests", dependencies: ["Zip"])
    ]
)
