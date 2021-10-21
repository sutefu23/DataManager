// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataManager",
    products: [
        .library(
            name: "DataManager",
            targets: ["DataManager"]),
    ],
    dependencies: [
        #if os(Windows)
            .package(url: "https://github.com/compnerd/swift-win32.git", .branch("main")),
        #endif
        #if os(Linux)
            .package(url: "https://github.com/swift-server/async-http-client.git", .branch("main")),
        #endif
    ],
    targets: [
        .target(
            name: "DataManager",
            dependencies: [
                #if os(Windows)
                    .product(name: "SwiftWin32", package: "SwiftWin32")
                #endif
                #if os(Linux)
                    .product(name: "AsyncHTTPClient", package: "async-http-client")
                #endif
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "DataManagerTests",
            dependencies: ["DataManager"],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
