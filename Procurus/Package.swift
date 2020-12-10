// swift-tools-version:5.3
import PackageDescription

let package = Package(
	name: "Procurus",
	products: [
		.executable(name: "Procurus", targets: ["Procurus"]),
	],
	dependencies: [],
	targets: [
		.target(name: "Procurus", dependencies: [])
	]
)
