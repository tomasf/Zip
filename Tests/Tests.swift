import Zip
import Testing
import Foundation

struct Tests {
    let fileManager = FileManager()
    let fileUUID = UUID()
    var fileURL: URL {
        fileManager.temporaryDirectory
            .appendingPathComponent(fileUUID.uuidString)
            .appendingPathExtension("zip")
    }

    let filename = "file1"
    let filename2 = "file2"
    let filename3 = "file3"
    let data = Data("data1".utf8)
    let data2 = Data("data2".utf8)
    let data3 = Data("data3".utf8)

    @Test
    func memory() throws {
        // Make an empty archive
        let archive = ZipArchive()
        #expect(try archive.entries.isEmpty)

        // Add 2 files
        try archive.addFile(at: filename, data: data)
        #expect(try archive.fileContents(at: filename) == data)
        try archive.addFile(at: filename2, data: data2)
        #expect(try archive.entries.count == 2)

        // Try to add a duplicate
        #expect(throws: ZipError.duplicateFileEntry) {
            try archive.addFile(at: filename2, data: data)
        }
        #expect(try archive.fileContents(at: filename2) == data2)

        // Finalize and make sure we get archive data
        let archiveData = try archive.finalize()
        #expect(archiveData.count >= 22) // Sanity check; >= header size

        // Initialize a new archive from that data
        let newArchive = try ZipArchive(data: archiveData)
        #expect(try newArchive.entries.count == 2)

        // Verify file contents
        #expect(try newArchive.fileContents(at: filename) == data)
        #expect(try newArchive.fileContents(at: filename2) == data2)

        // Modify it and make sure we get the same data back
        try newArchive.addFile(at: filename3, data: data3)
        #expect(try newArchive.fileContents(at: filename3) == data3)

        // Check that the new archive is larger than the old one
        let archiveData2 = try newArchive.finalize()
        #expect(archiveData2.count > archiveData.count)
    }

    @Test
    func directories() throws {
        let archive = ZipArchive()
        try archive.addFile(at: filename, data: data)
        try archive.addEmptyDirectory(path: "dir")

        #expect(throws: ZipError.invalidPath) {
            try archive.addFile(at: "foo/", data: data)
        }

        #expect(try archive.entries.count == 2)
    }

    @Test
    func files() throws {
        let archive = try ZipArchive(url: fileURL)
        try archive.addFile(at: filename, data: data)
        #expect(try archive.fileContents(at: filename) == data)
        try archive.addFile(at: filename2, data: data2)
        #expect(try archive.fileContents(at: filename2) == data2)
        try archive.finalize()

        let archive2 = try ZipArchive(url: fileURL)
        #expect(try archive2.fileContents(at: filename) == data)
        try archive2.addFile(at: filename3, data: data3)
        #expect(try archive2.entries.count == 3)
        try archive2.finalize()

        try? fileManager.removeItem(at: fileURL)
    }

    @Test
    func overwriteFile() throws {
        let archive1 = try ZipArchive(url: fileURL, mode: .overwrite)
        #expect(try archive1.entries.count == 0)
        try archive1.addFile(at: filename, data: data)
        try archive1.finalize()

        let archive2 = try ZipArchive(url: fileURL, mode: .overwrite)
        #expect(try archive2.entries.count == 0)
        try archive2.addFile(at: filename, data: data2)
        try archive2.finalize()

        let archive3 = try ZipArchive(url: fileURL, mode: .readAdd)
        #expect(try archive3.entries.count == 1)
        #expect(try archive3.fileContents(at: filename) == data2)
        archive3.close()
    }

    @Test
    func chunkedRead() throws {
        var gen = SystemRandomNumberGenerator()
        let randomData = (0..<100).map { _ in gen.next() }.withUnsafeBufferPointer(Data.init(buffer:))
        let chunkSize = 36

        let archive = ZipArchive()
        try archive.addFile(at: filename, data: randomData)

        var capturedData = Data()
        try archive.fileContents(at: filename, chunkSize: chunkSize) { chunk in
            #expect(chunk.count <= chunkSize)
            capturedData.append(chunk)
            return true
        }

        #expect(capturedData == randomData)
    }
}
