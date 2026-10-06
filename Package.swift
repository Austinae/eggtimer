// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EggTimer",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "EggTimer",
            resources: [.copy("Resources")]
        ),
    ]
)
