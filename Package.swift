// swift-tools-version:5.0

/**
 *  Sweep
 *  Copyright (c) John Sundell 2019
 *  Licensed under the MIT license (see LICENSE.md)
 */

import PackageDescription

let package = Package(
    name: "Sweep",
    products: [
        .library(
            name: "Sweep",
            targets: ["Sweep"]
        )
    ],
    targets: [
        .target(name: "Sweep"),
        .testTarget(
            name: "SweepTests",
            dependencies: ["Sweep"]
        )
    ]
)
