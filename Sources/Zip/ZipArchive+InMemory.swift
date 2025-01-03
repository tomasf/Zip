import Foundation
import Miniz

public extension ZipArchive<Data> {

    /// Creates a memory-based `ZipArchive` instance from the provided zip archive data.
    ///
    /// - Parameter data: The zip archive data used to initialize the archive.
    /// - Throws: An error if the archive initialization fails.
    convenience init(data: Data) throws {
        self.init(flag: true)

        // mz_zip_writer_init_from_reader_v2 sets m_pWrite to mz_zip_heap_write_func
        // This means miniz takes ownership of that memory and will free it.

        guard let input = malloc(data.count) else {
            throw ZipError.allocFailed
        }
        data.withUnsafeBytes {
            guard let pointer = $0.baseAddress else { return }
            memcpy(input, pointer, data.count)
        }

        try get {
            mz_zip_reader_init_mem(&$0, input, data.count, mz_uint32(MZ_ZIP_FLAG_WRITE_ALLOW_READING.rawValue))
        }

        try get {
            mz_zip_writer_init_from_reader_v2(&$0, nil, 0)
        }
    }

    /// Creates an empty `ZipArchive` instance.
    ///
    /// This initializer sets up an empty memory-based archive,
    /// allowing both reading and writing of entries.
    convenience init() {
        self.init(flag: true)

        try! get {
            mz_zip_writer_init_heap_v2(&$0, 0, 0, mz_uint32(MZ_ZIP_FLAG_WRITE_ALLOW_READING.rawValue))
        }
    }

    /// Finalizes the archive and returns the resulting zip archive data.
    ///
    /// This method ensures that all changes made to the archive are finalized and retrieves the
    /// completed archive data.
    ///
    /// - Returns: The finalized zip archive data.
    /// - Throws: An error if finalization fails or if the resulting data is invalid.
    func finalize() throws -> Data {
        var buffer: UnsafeMutableRawPointer?
        var size: Int = 0

        try get {
            mz_zip_writer_finalize_heap_archive(&$0, &buffer, &size)
        }

        guard let buffer else {
            throw ZipError.invalidData
        }

        defer { mz_free(buffer) }
        return Data(bytes: buffer, count: size)
    }
}
