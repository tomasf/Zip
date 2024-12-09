import Miniz
import Foundation

/// A ZIP archive stored in a file.
public class FileZipArchive: ZipArchive {
    private let url: URL

    /// Initializes a ZIP archive for writing to a file.
    ///
    /// - Parameter url: The URL of the ZIP file to write to.
    public init(forWritingTo url: URL) throws {
        self.url = url
        super.init()
        try url.path.withCString { filePath in
            if mz_zip_writer_init_file(&archive, filePath, 0) == 0 {
                throw Error.fileInitializationFailed
            }
        }
    }

    /// Initializes a ZIP archive for reading from a file.
    ///
    /// - Parameter url: The URL of the ZIP file to read from.
    public init(forReadingFrom url: URL) throws {
        self.url = url
        super.init()
        try url.path.withCString { filePath in
            if mz_zip_reader_init_file(&archive, filePath, 0) == 0 {
                throw Error.fileInitializationFailed
            }
        }
    }

    /// Finalizes the archive, making it ready for use.
    public func finalize() throws {
        if mz_zip_writer_finalize_archive(&archive) == 0 {
            throw Error.finalizeFailed
        }
    }
}
