import Foundation
import Miniz

public extension ZipArchive<URL> {
    /// Creates a `ZipArchive` instance for a disk-based zip archive at the specified file URL.
    ///
    /// If the file does not exist, a new archive is created at the specified location.
    ///
    /// - Parameter fileURL: The file URL of the zip archive to be read or created.
    /// - Parameter mode: The mode to use. The default, `Mode.readWrite`, lets you read an archive and, optionally, add new files to it. Use `Mode.overwrite` to create a new empty archive and overwrite an existing file if it exists.
    /// - Throws: An error if the initialization fails, such as if the file cannot be read or written.
    convenience init(url fileURL: URL, mode: Mode = .readAdd) throws {
        self.init(archive: .init())
        try fileURL.withUnsafeFileSystemRepresentation { path in
            if mode == .readAdd {
                do {
                    try get { mz_zip_reader_init_file(&$0, path, mz_uint32(MZ_ZIP_FLAG_WRITE_ALLOW_READING.rawValue)) }
                    try get { mz_zip_writer_init_from_reader_v2(&$0, path, 0) }
                } catch ZipError.fileOpenFailed {
                    try get { mz_zip_writer_init_file_v2(&$0, path, 0, mz_uint32(MZ_ZIP_FLAG_WRITE_ALLOW_READING.rawValue)) }
                }
            } else {
                try get { mz_zip_writer_init_file_v2(&$0, path, 0, 0) }
            }
        }
    }

    /// Closes the zip archive without writing the central directory to disk.
    ///
    /// This method ends the zip archive session without finalizing changes. Use this if you haven't
    /// made changes and do not need to save the archive.
    ///
    /// After calling this method, the archive is no longer usable, and you must not perform additional
    /// operations on it.
    func close() {
        mz_zip_writer_end(&archive)
    }

    /// Finalizes the zip archive and writes it to disk.
    ///
    /// This method ensures all changes are saved and closes the archive. After this method is called,
    /// no further modifications to the archive can be made.
    ///
    /// - Throws: An error if the finalization process fails.
    func finalize() throws {
        try get { mz_zip_writer_finalize_archive(&$0) }
        mz_zip_writer_end(&archive)
    }

    enum Mode {
        case readAdd
        case overwrite
    }
}
