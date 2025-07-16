// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "URLSessionAdapter",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8)],
    products: [
        .library(
            name: "URLSessionAdapter",
            targets: ["URLSessionAdapter"]),
    ],
    targets: [
        .target(
            name: "URLSessionAdapter",
            path: "Sources"),
        .testTarget(
            name: "URLSessionAdapterTests",
            dependencies: ["URLSessionAdapter"],
            path: "Tests"),
    ]
)
