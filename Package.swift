// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "text-splitter",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "TextSplitter", targets: ["TextSplitter"])
    ],
    targets: [
        .target(
            name: "TextSplitter",
            path: "Sources/TextSplitter"
        ),
        .testTarget(
            name: "TextSplitterTests",
            dependencies: ["TextSplitter"],
            path: "Tests/TextSplitterTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
