// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BenefitPay-iOS",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BenefitPay-iOS",
            targets: ["BenefitPay-iOS"]),
    ],
    dependencies: [ 
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/huri000/SwiftEntryKit.git", from: "1.0.0"),
        .package(url: "https://github.com/TakeScoop/SwiftyRSA.git", from: "1.0.0"),
        .package(url: "https://github.com/Tap-Payments/SharedDataModels-iOS.git", from: "0.0.1"),
        .package(url: "https://github.com/ahmdx/Robin", from: "0.98.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BenefitPay-iOS",
            dependencies: ["SwiftEntryKit",
                           "SwiftyRSA",
                           "Robin",
                          "SharedDataModels-iOS"],
            resources: [.copy("Resources/Close.png"),
                        .copy("Resources/BenefitLoader.gif"),
                        .process("Resources/TapBenefitPayMedia.xcassets")]
        ),
        .testTarget(
            name: "BenefitPay-iOSTests",
            dependencies: ["BenefitPay-iOS"]),
    ],
    swiftLanguageVersions: [.v5]
)
