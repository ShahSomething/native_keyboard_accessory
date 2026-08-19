// swift-tools-version: 5.9

import PackageDescription

// A single Objective-C target. Objective-C rather than Swift because the
// package's core is a runtime patch on an engine class: `class_addMethod`,
// `method_setImplementation`, and a C function used as an `IMP` are all
// first-class here, where in Swift they need `imp_implementationWithBlock` and
// `unsafeBitCast` gymnastics. Swift Package Manager also forbids mixing
// languages inside one target, so staying entirely in Objective-C keeps this a
// single target under both SPM and CocoaPods.
let package = Package(
    name: "native_keyboard_accessory",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "native-keyboard-accessory", targets: ["native_keyboard_accessory"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "native_keyboard_accessory",
            dependencies: [],
            path: "Sources/native_keyboard_accessory",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ]
        )
    ]
)
