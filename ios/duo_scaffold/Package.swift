// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "duo_scaffold",
  platforms: [
    .iOS("13.0")
  ],
  products: [
    .library(name: "duo-scaffold", targets: ["duo_scaffold"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "duo_scaffold",
      dependencies: []
    )
  ]
)
