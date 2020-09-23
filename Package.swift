// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataManager",
    platforms: [
          .macOS(.v10_12), .iOS(.v12), .tvOS(.v13)
      ],
    products: [
        .library(
            name: "DataManager",
            targets: ["DataManager"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "DataManager",
            dependencies: [],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "DataManagerTests",
            dependencies: ["DataManager"],
            resources: [
                .process("maru.ita")
            ]
        ),
    ]
)
