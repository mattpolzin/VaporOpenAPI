// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "VaporOpenAPI",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "VaporOpenAPI",
            targets: ["VaporOpenAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.50.0"),
        .package(url: "https://github.com/mattpolzin/VaporTypedRoutes.git", from: "0.9.0"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", .branch("release/3_0")),
        .package(url: "https://github.com/mattpolzin/OpenAPIReflection.git", .branch("openapikit-3"))
    ],
    targets: [
        .target(
            name: "VaporOpenAPI",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                "VaporTypedRoutes",
                "OpenAPIKit",
                "OpenAPIReflection"
            ]
        ),
        .testTarget(
            name: "VaporOpenAPITests",
            dependencies: [
                "VaporOpenAPI",
                .product(name: "XCTVapor", package: "vapor")
            ]
        ),
    ]
)
