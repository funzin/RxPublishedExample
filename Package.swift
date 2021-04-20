// swift-tools-version:5.3

import Foundation
import PackageDescription

let package = Package(
    name: "Uniko",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(
            name: "Uniko",
            targets: ["Uniko"]),
    ],
    dependencies: [
        .package(url: "https://github.com/reactivex/RxSwift", from: "6.0.0"),
        .package(url: "https://github.com/CombineCommunity/RxCombine", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "Uniko",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
                "RxCombine"
            ]),
    ]
)
