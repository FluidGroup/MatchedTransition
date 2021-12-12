// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "MatchedTransition",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(name: "MatchedTransition", targets: ["MatchedTransition"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MatchedTransition",
            dependencies: [],
            path: "MatchedTransition"
        )
    ]
)
