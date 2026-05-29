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
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0")
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
