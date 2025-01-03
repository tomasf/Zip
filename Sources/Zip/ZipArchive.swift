import Miniz
import Foundation

public class ZipArchive<Target> {
    var archive = mz_zip_archive()

    init(flag: Bool) {
        withUnsafeMutableBytes(of: &archive) { buffer in
            _ = buffer.initializeMemory(as: UInt8.self, repeating: 0)
        }
    }

    deinit {
        mz_zip_writer_end(&archive)
    }
}
