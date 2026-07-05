import Foundation
import Dispatch
@_implementationOnly import Miniz
#if canImport(Compression)
@_implementationOnly import Compression
#endif

// Fast deflate support. Large files are split into chunks that are deflated in parallel;
// each chunk ends on a byte-aligned sync-flush boundary with the final-block bit set only
// on the last one, so the concatenation forms a single standard deflate stream (the same
// technique pigz uses). Smaller files are compressed with Apple's libcompression where
// available, which is considerably faster than miniz at a comparable compression ratio.
// Everything here is self-contained; no libraries beyond the bundled miniz are required.

internal extension ZipArchive {
    /// Produces a raw deflate stream for the data, or nil if the regular miniz path should be used instead
    /// (small input on platforms without libcompression, incompressible data, or failure).
    static func fastDeflate(_ data: Data) -> Data? {
        if data.count >= parallelThreshold, let parallel = parallelDeflate(data) {
            return parallel
        }
        return singleShotDeflate(data)
    }

    /// The standard zip CRC32 of the data.
    static func crc32(of data: Data) -> UInt32 {
        data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            UInt32(mz_crc32(0, buffer.baseAddress?.assumingMemoryBound(to: UInt8.self), buffer.count))
        }
    }
}

private extension ZipArchive {
    static var parallelThreshold: Int { 2 << 20 }
    static var parallelChunkSize: Int { 512 << 10 }
    static var deflateLevel: Int32 { 6 }

    static func singleShotDeflate(_ data: Data) -> Data? {
        #if canImport(Compression)
        // Only worthwhile if the result is smaller than the input; encoding into a
        // buffer one byte short of the input size makes libcompression fail otherwise.
        let capacity = data.count - 1
        guard capacity > 0 else { return nil }

        guard let buffer = malloc(capacity) else { return nil }
        let compressedSize = data.withUnsafeBytes { (source: UnsafeRawBufferPointer) in
            compression_encode_buffer(
                buffer.assumingMemoryBound(to: UInt8.self), capacity,
                source.baseAddress!.assumingMemoryBound(to: UInt8.self), data.count,
                nil, COMPRESSION_ZLIB
            )
        }

        guard compressedSize > 0 else {
            free(buffer)
            return nil
        }
        return Data(bytesNoCopy: buffer, count: compressedSize, deallocator: .free)
        #else
        return nil
        #endif
    }

    /// Deflates the data as independent chunks on all available cores. Each chunk but the last ends
    /// with a byte-aligned sync flush and no final-block bit, so concatenating the chunks yields a
    /// single valid deflate stream.
    static func parallelDeflate(_ data: Data) -> Data? {
        let chunkCount = (data.count + parallelChunkSize - 1) / parallelChunkSize
        let chunks = UnsafeMutableBufferPointer<Data?>.allocate(capacity: chunkCount)
        chunks.initialize(repeating: nil)
        defer {
            chunks.deinitialize()
            chunks.deallocate()
        }

        data.withUnsafeBytes { (source: UnsafeRawBufferPointer) in
            DispatchQueue.concurrentPerform(iterations: chunkCount) { chunkIndex in
                let range = (chunkIndex * parallelChunkSize)..<Swift.min((chunkIndex + 1) * parallelChunkSize, source.count)
                let isLast = chunkIndex == chunkCount - 1
                chunks[chunkIndex] = deflateChunk(UnsafeRawBufferPointer(rebasing: source[range]), isLast: isLast)
            }
        }

        var output = Data(capacity: data.count)
        for chunk in chunks {
            guard let chunk else { return nil }
            output.append(chunk)
        }
        return output.count < data.count ? output : nil
    }

    static func deflateChunk(_ input: UnsafeRawBufferPointer, isLast: Bool) -> Data? {
        guard let compressor = tdefl_compressor_alloc() else { return nil }
        defer { tdefl_compressor_free(compressor) }

        // Negative window bits produce a raw deflate stream without zlib framing, as zip requires
        let flags = tdefl_create_comp_flags_from_zip_params(deflateLevel, -15, Int32(MZ_DEFAULT_STRATEGY))
        guard tdefl_init(compressor, nil, nil, Int32(flags)) == TDEFL_STATUS_OKAY else { return nil }

        // Worst case is stored blocks: 5 bytes of header per 64KB, plus the sync flush marker
        let capacity = input.count + input.count / 8 + 128
        guard let buffer = malloc(capacity) else { return nil }

        var inputSize = input.count
        var outputSize = capacity
        let status = tdefl_compress(
            compressor, input.baseAddress, &inputSize,
            buffer, &outputSize,
            isLast ? TDEFL_FINISH : TDEFL_SYNC_FLUSH
        )

        guard status == (isLast ? TDEFL_STATUS_DONE : TDEFL_STATUS_OKAY), inputSize == input.count else {
            free(buffer)
            return nil
        }

        return Data(bytesNoCopy: buffer, count: outputSize, deallocator: .free)
    }
}
