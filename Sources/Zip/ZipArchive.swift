import Miniz
import Foundation

public class ZipArchive<Target> {
    var archive: mz_zip_archive

    init(archive: mz_zip_archive) {
        self.archive = archive
    }

    deinit {
        mz_zip_writer_end(&archive)
    }
}
