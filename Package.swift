// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MacPatroNative",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MacPatroNativeApp",
            targets: ["MacPatroNativeApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MacPatroKit",
            path: "MacPatroNative/Sources",
            exclude: ["App"],
            resources: [
                .copy("../Resources")
            ]
        ),
        .executableTarget(
            name: "MacPatroNativeApp",
            dependencies: ["MacPatroKit"],
            path: "MacPatroNative/Sources/App"
        ),
        .testTarget(
            name: "MacPatroNativeTests",
            dependencies: ["MacPatroKit"],
            path: "MacPatroNative/Tests/MacPatroNativeTests"
        )
    ]
)
