// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_tex_js_ios",
    platforms: [
        .iOS("11.0")
    ],
    products: [
        .library(name: "flutter-tex-js-ios", targets: ["flutter_tex_js_ios"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_tex_js_ios",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .copy("katex")
            ]
        )
    ]
)
