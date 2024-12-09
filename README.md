# Zip

Zip is a lightweight Swift package for working with Zip archives. It's built on top of [Miniz](https://github.com/richgel999/miniz) and includes the its entire implementation, so no external dependencies are required.

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
	.package(url: "https://github.com/tomasf/zip.git", from: "1.0.0")
]
```

## Usage
### Writing to a file-based archive

```swift
import Zip

let archive = try FileZipArchive(forWritingTo: URL(fileURLWithPath: "example.zip"))
archive.addFile(name: "hello.txt", data: Data("Hello, Zip!".utf8))
try archive.finalize()
```

### Reading from a file-based archive

```swift
let archive = try FileZipArchive(forReadingFrom: URL(fileURLFileWithPath: "example.zip"))
if let data = archive.readFile(name: "hello.txt"), let text = String(data: data, encoding: .utf8) {
	print("File content: \(text\")"
}
```