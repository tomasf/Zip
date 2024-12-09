import Miniz

/// A ZIP archive stored in memory.
public class MemoryZipArchive: ZipArchive {
    /// Initializes a ZIP archive for writing to memory.
    public override init() {
        super.init()
        if mz_zip_writer_init_heap(&archive, 0, 0) == 0 {
            fatalError("Failed to initialize in-memory ZIP archive.")
        }
    }

    /// Initializes a ZIP archive for reading from memory.
    ///
    /// - Parameter data: The memory buffer containing the ZIP archive.
    public init(data: Data) throws {
        super.init()
        try data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress,
                  mz_zip_reader_init_mem(&archive, baseAddress, buffer.count, 0) == 0
            else {
                throw Error.invalidZipData
            }
        }
    }

    /// Finalizes the archive and returns its data.
    ///
    /// - Returns: The finalized archive as `Data`.
    public func finalize() throws -> Data {
        var buffer: UnsafeMutableRawPointer?
        var size: Int = 0

        guard mz_zip_writer_finalize_heap_archive(&archive, &buffer, &size) == 1,
              let rawBuffer = buffer
        else {
            throw Error.finalizeFailed
        }

        defer { mz_free(rawBuffer) }
        return Data(bytes: rawBuffer, count: size)
    }
}
