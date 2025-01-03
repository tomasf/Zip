import Foundation
import Miniz

internal extension ZipArchive {
    func get<P: _Pointer>(_ body: (inout mz_zip_archive) -> P?) throws(ZipError) -> P {
        guard let result = body(&archive) else {
            throw ZipError(mzError: mz_zip_get_last_error(&archive))
        }
        return result
    }

    @discardableResult
    func get<I: BinaryInteger>(with success: Success = .positive, _ body: (inout mz_zip_archive) -> I) throws(ZipError) -> I {
        let result = body(&archive)

        if result < 0 || (success == .positive && result == 0) {
            throw ZipError(mzError: mz_zip_get_last_error(&archive))
        }

        return result
    }

    enum Success {
        case positive
        case nonNegative
    }
}
