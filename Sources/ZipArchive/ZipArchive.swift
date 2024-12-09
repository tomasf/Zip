import Foundation
import Miniz

/// An abstract base class for working with ZIP archives.
///
/// This class provides common functionality for reading and writing ZIP archives.
/// Use one of the concrete subclasses, `FileZipArchive` for file-based archives or
/// `MemoryZipArchive` for in-memory archives.
public class ZipArchive {
    internal var archive = mz_zip_archive()

    fileprivate init() {
        memset(&archive, 0, MemoryLayout.size(ofValue: archive))
    }

    /// Adds a file to the archive with the specified name and data.
    ///
    /// - Parameters:
    ///   - name: The name of the file in the archive.
    ///   - data: The file's data.
    ///   - compression: The compression level. Defaults to `.default`.
    public func addFile(name: String, data: Data, compression: CompressionLevel = .default) {
        name.withCString { fileName in
            data.withUnsafeBytes { buffer in
                guard let rawPointer = buffer.baseAddress else {
                    fatalError("Failed to get raw pointer from data.")
                }

                if mz_zip_writer_add_mem(&archive, fileName, rawPointer, buffer.count, mz_uint(compression.value)) == 0 {
                    fatalError("Failed to add file \(name) to ZIP archive.")
                }
            }
        }
    }

    /// Reads a file from the archive by its name.
    ///
    /// - Parameter name: The name of the file to read.
    /// - Returns: The file's data, or `nil` if the file is not found.
    public func readFile(name: String) -> Data? {
        var size: Int = 0
        let fileIndex = name.withCString({ mz_zip_reader_locate_file(&archive, $0, nil, 0) })
        guard fileIndex >= 0,
              let buffer = mz_zip_reader_extract_to_heap(&archive, UInt32(fileIndex), &size, 0)
        else {
            return nil
        }

        defer { mz_free(buffer) }
        return Data(bytes: buffer, count: size)
    }

    /// Reads a file from the archive iteratively, chunk by chunk.
    ///
    /// - Parameters:
    ///   - name: The name of the file to read.
    ///   - chunkSize: The size of each chunk to read.
    ///   - handler: A closure that processes each chunk. Return `false` to stop reading.
    public func readFile(name: String, chunkSize: Int, handler: (Data) -> Bool) throws {
        guard let iter = mz_zip_reader_extract_file_iter_new(&archive, name, 0) else {
            throw Error.fileNotFound
        }
        defer { mz_zip_reader_extract_iter_free(iter) }

        let buffer = UnsafeMutableRawPointer.allocate(byteCount: chunkSize, alignment: MemoryLayout<UInt8>.alignment)
        defer { buffer.deallocate() }

        while true {
            let bytesRead = mz_zip_reader_extract_iter_read(iter, buffer, chunkSize)
            if bytesRead < 0 {
                throw Error.failedToReadFile
            }
            guard bytesRead > 0, handler(Data(bytes: buffer, count: bytesRead)) else {
                break
            }
        }
    }

    /// Retrieves a list of files contained in the archive.
    public var files: [File] {
        (0..<mz_zip_reader_get_num_files(&archive)).compactMap { index in
            var nameBuffer: [CChar] = .init(repeating: 0, count: Int(MZ_ZIP_MAX_ARCHIVE_FILENAME_SIZE))
            var fileStat = mz_zip_archive_file_stat()

            guard mz_zip_reader_get_filename(&archive, UInt32(index), &nameBuffer, UInt32(nameBuffer.count)) > 0,
                  mz_zip_reader_file_stat(&archive, UInt32(index), &fileStat) != 0,
                  let name = String(utf8String: nameBuffer)
            else {
                return nil
            }

            return File(name: name, uncompressedSize: fileStat.m_uncomp_size, compressedSize: fileStat.m_comp_size)
        }
    }

    deinit {
        mz_zip_writer_end(&archive)
        mz_zip_reader_end(&archive)
    }

    /// Represents a file in the ZIP archive.
    public struct File {
        /// The name of the file.
        public let name: String

        /// The uncompressed size of the file, in bytes.
        public let uncompressedSize: UInt64

        /// The compressed size of the file, in bytes.
        public let compressedSize: UInt64
    }

    /// Represents the compression level for files added to the archive.
    public struct CompressionLevel: ExpressibleByIntegerLiteral, Sendable {
        /// The underlying compression level value.
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

    /// An error that can occur when working with ZIP archives.
    public enum Error: Swift.Error {
        /// Finalizing the archive failed.
        case finalizeFailed

        /// Initialization of a file-based archive failed.
        case fileInitializationFailed

        /// Invalid ZIP data was provided.
        case invalidZipData

        /// The specified file could not be found in the archive.
        case fileNotFound

        /// Reading from the archive failed.
        case failedToReadFile
    }
}
