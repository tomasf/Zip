# Zip

Zip is a lightweight cross-platform Swift package for working with Zip archives. It's built on top of [Miniz](https://github.com/richgel999/miniz) and includes its entire implementation, so no external dependencies are required.

Zip runs on macOS, Windows and Linux.

[![Swift](https://github.com/tomasf/Zip/actions/workflows/swift.yml/badge.svg)](https://github.com/tomasf/Zip/actions/workflows/swift.yml)

![Platforms](https://img.shields.io/badge/Platforms-macOS_%7C_Linux_%7C_Windows-47D?logo=swift&logoColor=white)

## Features

- Add and read files from ZIP archives.
- Support for both file-based and in-memory archives.
- Iterative reading of files in chunk.
- Configurable compression levels.
- Minimalistic and modern Swift API.

## Installation
Add the package to your project using Swift Package Manager. In your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/tomasf/Zip.git", from: "2.0.0")
]
```

## Examples
### Making a new memory-based archive

```swift
let archive = ZipArchive()
try archive.addFile(at: "content.json", data: jsonData)
let zipData = try archive.finalize()
```

### Reading from an existing archive in memory

```swift
let newArchive = try ZipArchive(data: zipData)

let data = try archive.fileContents(at: "hello.txt")
if let text = String(data: data, encoding: .utf8) {
    print("Hello.txt contains: \(text)")
}
```

### Writing a file-based archive

```swift
let archive = try ZipArchive(url: archiveURL)
try archive.addFile(at: "hello.txt", data: Data("Hello, Zip!".utf8))
try archive.finalize() // Writes Zip data to disk
```

## Contributions

Contributions are welcome! If you have ideas, suggestions, or bug reports, feel free to open an issue on GitHub. Pull requests are also appreciated.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
