// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IrisEyeGlanceCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "IrisEyeGlanceCore", targets: ["IrisEyeGlanceCore"]),
    ],
    targets: [
        .target(name: "IrisEyeGlanceCore"),
        .testTarget(
            name: "IrisEyeGlanceCoreTests",
            dependencies: ["IrisEyeGlanceCore"]
        ),
    ]
)
