import Foundation
import Miniz

public extension ZipArchive<URL> {
    /// Creates a `ZipArchive` instance for a disk-based zip archive at the specified file URL.
    ///
    /// If the file does not exist, a new archive is created at the specified location.
    ///
    /// - Parameter fileURL: The file URL of the zip archive to be read or created.
    /// - Throws: An error if the initialization fails, such as if the file cannot be read or written.
    convenience init(url fileURL: URL) throws {
        self.init(flag: true)

        let path = fileURL.path
        if FileManager().fileExists(atPath: path) {
            try get { mz_zip_reader_init_file(&$0, path, mz_uint32(MZ_ZIP_FLAG_WRITE_ALLOW_READING.rawValue)) }
            try get { mz_zip_writer_init_from_reader_v2(&$0, path, 0) }
        } else {
            try get { mz_zip_writer_init_file_v2(&$0, path, 0, mz_uint32(MZ_ZIP_FLAG_WRITE_ALLOW_READING.rawValue)) }
        }
    }

    /// Finalizes the zip archive and writes it to disk.
    ///
    /// This method ensures all changes are saved and closes the archive. After this method is called,
    /// no further modifications to the archive can be made.
    ///
    /// - Throws: An error if the finalization process fails.
    func finalize() throws {
        try get { mz_zip_writer_finalize_archive(&$0) }
    }
}
