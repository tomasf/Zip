import Miniz
import Foundation

/// Swift representation of mz_zip_error
public enum ZipError: Int, Swift.Error {
    case invalidData
    case invalidPath
    case duplicateFileEntry

    // miniz errors
    case noError
    case undefinedError
    case tooManyFiles
    case fileTooLarge
    case unsupportedMethod
    case unsupportedEncryption
    case unsupportedFeature
    case failedFindingCentralDir
    case notAnArchive
    case invalidHeaderOrCorrupted
    case unsupportedMultiDisk
    case decompressionFailed
    case compressionFailed
    case unexpectedDecompressedSize
    case crcCheckFailed
    case unsupportedCDirSize
    case allocFailed
    case fileOpenFailed
    case fileCreateFailed
    case fileWriteFailed
    case fileReadFailed
    case fileCloseFailed
    case fileSeekFailed
    case fileStatFailed
    case invalidParameter
    case invalidFilename
    case bufTooSmall
    case internalError
    case fileNotFound
    case archiveTooLarge
    case validationFailed
    case writeCallbackFailed

    internal init(mzError: mz_zip_error) {
        self = Self(rawValue: Self.noError.rawValue + Int(mzError.rawValue)) ?? .noError
    }
}
