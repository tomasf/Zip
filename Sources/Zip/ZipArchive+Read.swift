import Foundation
import Miniz

public extension ZipArchive {
    /// Reads a file from the archive by its path.
    ///
    /// - Parameter path: The path of the file to read.
    /// - Returns: The file's data.
    /// - Throws: An error if the file cannot be read from the archive.
    func fileContents(at path: String) throws -> Data {
        var size = 0
        let fileIndex = try get(with: .nonNegative) { mz_zip_reader_locate_file(&$0, path, nil, 0) }
        let buffer = try get { mz_zip_reader_extract_to_heap(&$0, UInt32(fileIndex), &size, 0) }

        defer { mz_free(buffer) }
        return Data(bytes: buffer, count: size)
    }

    /// Checks whether a file or directory exists at the specified path in the archive.
    ///
    /// - Parameter path: The path to check.
    /// - Returns: `true` if an entry exists at the specified path, otherwise `false`.
    func hasEntry(at path: String) -> Bool {
        mz_zip_reader_locate_file(&archive, path, nil, 0) >= 0
    }

    /// Reads a file from the archive iteratively, chunk by chunk.
    ///
    /// - Parameters:
    ///   - path: The path of the file to read.
    ///   - chunkSize: The size of each chunk to read, in bytes.
    ///   - handler: A closure that processes each chunk of data. The closure returns `false` to stop reading, or `true` to continue.
    /// - Throws: An error if the file cannot be read or if an issue occurs during iteration.
    func fileContents(at path: String, chunkSize: Int, handler: (Data) -> Bool) throws {
        let iterator = try get { mz_zip_reader_extract_file_iter_new(&$0, path, 0) }
        defer { mz_zip_reader_extract_iter_free(iterator) }

        let buffer = UnsafeMutableRawPointer.allocate(byteCount: chunkSize, alignment: MemoryLayout<UInt8>.alignment)
        defer { buffer.deallocate() }

        while true {
            let bytesRead = try get(with: .nonNegative) { _ in
                mz_zip_reader_extract_iter_read(iterator, buffer, chunkSize)
            }
            guard bytesRead > 0, handler(Data(bytes: buffer, count: bytesRead)) else {
                break
            }
        }
    }

    /// Retrieves a list of all files and directories contained in the archive.
    ///
    /// - Returns: An array of `Entry` objects representing the files and directories in the archive.
    /// - Throws: An error if any entry cannot be read.
    var entries: [Entry] {
        get throws {
            var nameBuffer: [CChar] = .init(repeating: 0, count: MZ_ZIP_MAX_ARCHIVE_FILENAME_SIZE)
            var fileStat = mz_zip_archive_file_stat()
            let count = mz_zip_reader_get_num_files(&archive)

            return try (0..<count).map { (index: UInt32) throws -> Entry in
                try get { mz_zip_reader_get_filename(&$0, index, &nameBuffer, UInt32(nameBuffer.count)) }
                try get { mz_zip_reader_file_stat(&$0, index, &fileStat) }

                guard let path = String(utf8String: nameBuffer) else {
                    throw ZipError.invalidPath
                }

                return Entry(
                    path: path,
                    kind: path.hasSuffix("/") ? Entry.Kind.directory : .file,
                    uncompressedSize: fileStat.m_uncomp_size,
                    compressedSize: fileStat.m_comp_size
                )
            }
        }
    }
}

/// Represents a file or directory in the ZIP archive.
public struct Entry {
    /// The path of the file or directory.
    public let path: String

    /// The type of the entry, indicating whether it is a file or a directory.
    public let kind: Kind

    /// The uncompressed size of the file, in bytes.
    ///
    /// For directories, this value is typically zero.
    public let uncompressedSize: UInt64

    /// The compressed size of the file, in bytes.
    ///
    /// For directories, this value is typically zero.
    public let compressedSize: UInt64

    /// Specifies whether the entry is a file or a directory.
    public enum Kind: Hashable {
        /// A file entry.
        case file
        /// A directory entry.
        case directory
    }
}
