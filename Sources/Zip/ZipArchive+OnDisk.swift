import Foundation
import Miniz

public extension ZipArchive<URL> {
    /// Creates a `ZipArchive` instance for a disk-based zip archive at the specified file URL.
    ///
    /// If the file does not exist and the mode is `readAdd`, a new archive is created at the specified location.
    /// If the mode is `overwrite`, any existing archive at the location is replaced.
    /// If the mode is `readOnly`, the archive is opened strictly for reading, and must already exist.
    ///
    /// - Parameter fileURL: The file URL of the zip archive to be read or created.
    /// - Parameter mode: The mode to use. Use `.readOnly` to read an existing archive, `.readAdd` to read and add
    ///   files (creating the archive if it doesn’t exist), or `.overwrite` to create a new empty archive, replacing
    ///   any existing file.
    /// - Throws: An error if the initialization fails, such as if the file cannot be read or written.
    ///
    convenience init(url fileURL: URL, mode: Mode = .readAdd) throws {
        self.init(archive: .init())
        try fileURL.withUnsafeFileSystemRepresentation { path in
            switch mode {
            case .readOnly:
                try get { mz_zip_reader_init_file(&$0, path, 0) }
                
            case .readAdd:
                do {
                    try get { mz_zip_reader_init_file(&$0, path, mz_uint32(MZ_ZIP_FLAG_WRITE_ALLOW_READING.rawValue)) }
                    try get { mz_zip_writer_init_from_reader_v2(&$0, path, 0) }
                } catch ZipError.fileOpenFailed {
                    try get { mz_zip_writer_init_file_v2(&$0, path, 0, mz_uint32(MZ_ZIP_FLAG_WRITE_ALLOW_READING.rawValue)) }
                }
                
            case .overwrite:
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
    ///
    func close() {
        mz_zip_writer_end(&archive)
    }
    
    /// Finalizes the zip archive and writes it to disk.
    ///
    /// This method ensures all changes are saved and closes the archive. After this method is called,
    /// no further modifications to the archive can be made.
    ///
    /// - Throws: An error if the finalization process fails.
    ///
    func finalize() throws {
        try get { mz_zip_writer_finalize_archive(&$0) }
        mz_zip_writer_end(&archive)
    }

    /// Describes the mode to use when opening a zip archive.
    enum Mode {
        /// Opens an existing archive for reading only. No changes can be made.
        case readOnly
        
        /// Opens an existing archive for reading and allows adding new files. If the archive doesn't exist, a new one will be created.
        case readAdd
        
        /// Creates a new empty archive, overwriting any existing file at the specified location.
        case overwrite
    }
}
