import Foundation
import Miniz

public extension ZipArchive {
    /// Adds a file to the archive with the specified data and path.
    ///
    /// - Parameters:
    ///   - path: The path of the file in the archive.
    ///   - data: The file's data.
    ///   - compression: The compression level. Defaults to `.default`.
    ///
    func addFile(at path: String, data: Data, compression: CompressionLevel = .default) throws {
        // miniz doesn't check for duplicates, so we do it manually.
        // I'd prefer to replace the entry, but miniz doesn't allow that.
        guard !hasEntry(at: path) else {
            throw ZipError.duplicateFileEntry
        }

        guard !path.hasSuffix("/") else {
            throw ZipError.invalidPath
        }

        try data.withUnsafeBytes { buffer in
            guard let rawPointer = buffer.baseAddress else {
                fatalError("Failed to get raw pointer from data.")
            }

            try get {
                mz_zip_writer_add_mem(&$0, path, rawPointer, buffer.count, mz_uint(compression.value))
            }
        }
    }

    /// Adds an empty directory to the archive.
    ///
    /// If the directory already contains files, you can skip this step as directories are created
    /// automatically based on file paths.
    ///
    /// - Parameter path: The path of the directory in the archive.
    /// - Throws: An error if the directory cannot be added.
    func addEmptyDirectory(path: String) throws {
        let fullPath = path.hasSuffix("/") ? path : path + "/"

        try get {
            mz_zip_writer_add_mem(&$0, fullPath, nil, 0, 0)
        }
    }
}

/// Represents the compression level for files added to the archive.
public struct CompressionLevel: ExpressibleByIntegerLiteral, Sendable {
    let value: Int

    /// No compression.
    public static let none = Self(0)

    /// Fastest compression.
    public static let fastest = Self(1)

    /// Default compression level.
    public static let `default` = Self(6)

    /// Best compression, prioritizing size over speed.
    public static let best = Self(9)

    /// Initializes a `CompressionLevel` with a specific value.
    /// - Parameter level: The compression level value.
    public init(_ level: Int) {
        value = level
    }

    /// Initializes a `CompressionLevel` using an integer literal.
    /// - Parameter value: The integer value representing the compression level.
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}
