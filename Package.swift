// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataManager",
    platforms: [
          .macOS(.v10_12), .iOS(.v12), .tvOS(.v13)
      ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DataManager",
            targets: ["DataManager"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DataManager",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("板加工在庫一覧.csv"),
                .process("付属品封筒裏面.pdf")
            ]
        ),
        .testTarget(
            name: "DataManagerTests",
            dependencies: ["DataManager"],
            path: "Tests",
            resources: [
                .process("maru.ita")
            ]
        ),
    ]
)
