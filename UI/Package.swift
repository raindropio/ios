// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "UI",
    defaultLocalization: "en",
    platforms: [
        .macOS("13.0"),
        .iOS("16.4"),
        .visionOS("1.0")
    ],
    products: [
        .library(
            name: "UI",
            targets: ["UI"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/onevcat/Kingfisher",
            from: "8.9.0"
        ),
        .package(path: "Backport"),
    ],
    targets: [
        .target(
            name: "UI",
            dependencies: [
                .product(name: "Kingfisher", package: "Kingfisher"),
                .byName(name: "Backport")
            ],
            path: "",
            resources: [
                .process("Localizable.xcstrings")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency")
            ]
        )
    ]
)
