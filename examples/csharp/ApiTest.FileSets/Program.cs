using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.IO.Pipelines;
using System.Linq;
using System.Security.Cryptography;
using System.Threading.Tasks;
using ApiTest.Shared;
using Calcasa.Api.Api;
using Calcasa.Api.Client;
using Calcasa.Api.Model;
using CommunityToolkit.HighPerformance;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using MimeKit;
using FileInfo = Calcasa.Api.Model.FileInfo;

const string FileSetType = "test-file-set";

// Shared bootstrap: loads .env values and configures OAuth + API host.
var host = ExamplesConfiguration.CreateApiHost(args);
var logger = host.Services.GetRequiredService<ILoggerFactory>().CreateLogger("ApiTest.FileSets");
var fileSetDirectory = ExamplesConfiguration.GetRequiredEnvironmentVariable("CALCASA_TEST_FILE_SET_PATH");

if (!Directory.Exists(fileSetDirectory))
{
    throw new DirectoryNotFoundException($"Directory {fileSetDirectory} not found.");
}

logger.LogInformation("Found test file set path: {FileSetDirectory}", fileSetDirectory);

var fileSetRevision = GetFileSetRevision();

// Build a deterministic local manifest first so file metadata and order are stable.
var fs = host.Services.GetRequiredService<IFileSetsApi>();
var manifest = BuildFileManifest(fileSetDirectory);
PrintManifest(manifest, logger);

// Read inbound limits and validate before uploading any file data.
var limitsResponse = await fs.GetFileSetLimitsAsync();
if (!limitsResponse.TryOk(out var limitsResult) || limitsResult is null)
{
    limitsResponse.HandleErrorResponse();
    throw new InvalidOperationException("Failed to retrieve file set limits.");
}

var limits = limitsResult;

PrintLimits(limits, logger);
ValidateManifestAgainstLimits(manifest, limits);

var chunkSizeBytesLong = checked(limits.InboundMaxCompressedChunkSizeInKiloBytes * 1000L);
if (chunkSizeBytesLong <= 0)
{
    throw new ArgumentException("GetFileSetLimits returned an invalid InboundMaxCompressedChunkSizeInKiloBytes value.");
}

if (chunkSizeBytesLong > int.MaxValue)
{
    throw new ArgumentException($"Inbound chunk size is too large to allocate a buffer: {chunkSizeBytesLong} bytes.");
}

var chunkSizeBytes = (int)chunkSizeBytesLong;

// Create a new inbound file set using type/revision/period identity.
var createRequest = new CreateInboundFileSetRequest(
    type: FileSetType,
    revision: fileSetRevision,
    period: DateOnly.FromDateTime(DateTime.UtcNow),
    files: manifest.Select(entry => entry.ApiFile).ToList()
);

logger.LogInformation(
    "Using file set identity type={FileSetType}, revision={FileSetRevision}, period={Period}.",
    FileSetType, fileSetRevision, createRequest.Period
);

var inboundFileSetResponse = await fs.CreateInboundFileSetAsync(createRequest);
if (!inboundFileSetResponse.TryOk(out var inboundFileSetResult) || inboundFileSetResult is null)
{
    inboundFileSetResponse.HandleErrorResponse();
    throw new InvalidOperationException("Failed to create inbound file set.");
}

var inboundFileSet = inboundFileSetResult;

var inboundFileSetId = inboundFileSet.Id;
logger.LogInformation("Created inbound file set {InboundFileSetId} with state {State}.", inboundFileSetId, inboundFileSet.State);

// Upload all files chunk-by-chunk, then confirm to start server-side verification.
await UploadManifestAsync(fs, inboundFileSetId, manifest, chunkSizeBytes, logger);

var confirmedFileSetResponse = await fs.ConfirmInboundFileSetByIdAsync(inboundFileSetId);
if (!confirmedFileSetResponse.TryOk(out var confirmedFileSetResult) || confirmedFileSetResult is null)
{
    confirmedFileSetResponse.HandleErrorResponse();
    throw new InvalidOperationException("Failed to confirm inbound file set.");
}

var confirmedFileSet = confirmedFileSetResult;

logger.LogInformation("Confirmed inbound file set {InboundFileSetId} with state {State}.", confirmedFileSet.Id, confirmedFileSet.State);

static int GetFileSetRevision()
{
    // Allow deterministic retries via env override; otherwise use timestamp-based revision for testing.
    var revisionFromEnvironment = Environment.GetEnvironmentVariable("CALCASA_TEST_FILE_SET_REVISION");
    if (!string.IsNullOrWhiteSpace(revisionFromEnvironment))
    {
        if (!int.TryParse(revisionFromEnvironment, out var parsedRevision))
        {
            throw new ArgumentException(
                $"CALCASA_TEST_FILE_SET_REVISION must be a valid integer, got '{revisionFromEnvironment}'."
            );
        }

        return parsedRevision;
    }

    return checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
}

static List<LocalFileEntry> BuildFileManifest(string rootDirectory)
{
    // The API expects file names relative to the file-set root and stable file indices.
    var rootPath = Path.GetFullPath(rootDirectory);
    var files = Directory
        .GetFiles(rootPath, "*", SearchOption.AllDirectories)
        .OrderBy(path => path, StringComparer.Ordinal)
        .ToList();

    if (files.Count == 0)
    {
        throw new ArgumentException("The test file set directory does not contain any files to upload.");
    }

    var manifest = new List<LocalFileEntry>(capacity: files.Count);

    for (var index = 0; index < files.Count; index++)
    {
        var filePath = files[index];
        var relativeName = Path.GetRelativePath(rootPath, filePath).Replace('\\', '/');
        var contentType = MimeTypes.GetMimeType(filePath);

        if (string.IsNullOrWhiteSpace(contentType))
        {
            contentType = "application/octet-stream";
        }

        var fileInfo = new System.IO.FileInfo(filePath);
        var apiFile = new InboundFileInfo(
            index: index,
            name: relativeName,
            contentHash: CalculateSha256(filePath),
            size: fileInfo.Length,
            contentType: contentType,
            compression: CompressionType.Gzip // Change if appropriate if you use a different compression method.
        );

        manifest.Add(new LocalFileEntry(filePath, apiFile));
    }

    return manifest;
}

static string CalculateSha256(string filePath)
{
    using var stream = File.OpenRead(filePath);
    using var sha256 = SHA256.Create();
    return Convert.ToHexString(sha256.ComputeHash(stream));
}

static void PrintManifest(IReadOnlyList<LocalFileEntry> manifest, ILogger logger)
{
    logger.LogInformation("Preparing {FileCount} files for upload:", manifest.Count);
    foreach (var entry in manifest)
    {
        logger.LogInformation(
            "- [{Index}] {Name} ({Size} bytes, {ContentType})",
            entry.ApiFile.Index, entry.ApiFile.Name, entry.ApiFile.Size, entry.ApiFile.ContentType
        );
    }
}

static UploadReadStream CreateUploadReadStream(LocalFileEntry entry)
{
    // Stream compressed data through a pipe so uploads do not buffer full compressed files in memory.
    var fileStream = File.OpenRead(entry.Path);

    if (entry.ApiFile.Compression != CompressionType.Gzip && entry.ApiFile.Compression != CompressionType.Brotli)
    {
        return new UploadReadStream(fileStream, static stream => stream.DisposeAsync());
    }

    var pipe = new Pipe();
    var readerStream = pipe.Reader.AsStream();

    var compressionTask = Task.Run(async () =>
    {
        try
        {
            await using var sourceStream = fileStream;
            await using var writerStream = pipe.Writer.AsStream(leaveOpen: true);

            if (entry.ApiFile.Compression == CompressionType.Brotli)
            {
                await using var compressedStream = new BrotliStream(writerStream, CompressionLevel.Optimal, leaveOpen: true);
                await sourceStream.CopyToAsync(compressedStream);
            }
            else
            {
                await using var compressedStream = new GZipStream(writerStream, CompressionLevel.Optimal, leaveOpen: true);
                await sourceStream.CopyToAsync(compressedStream);
            }

            await pipe.Writer.CompleteAsync();
        }
        catch (Exception ex)
        {
            await pipe.Writer.CompleteAsync(ex);
            throw;
        }
    });

    return new UploadReadStream(
        readerStream,
        async stream =>
        {
            await compressionTask;
            await stream.DisposeAsync();
            await pipe.Reader.CompleteAsync();
        }
    );
}

static void PrintLimits(FileSetLimits limits, ILogger logger)
{
    logger.LogInformation(
        "Inbound limits: maxFiles={MaxFiles}, maxFileSize={MaxFileSize} bytes, maxTotalSize={MaxTotalSize} bytes, maxChunkSize={MaxChunkSize} bytes, ttl={Ttl} seconds",
        limits.InboundMaxTotalFiles,
        limits.InboundMaxFileSizeInKiloBytes * 1000L,
        limits.InboundMaxTotalSizeInKiloBytes * 1000L,
        limits.InboundMaxCompressedChunkSizeInKiloBytes * 1000L,
        limits.InboundTtlInSeconds
    );
}

static void ValidateManifestAgainstLimits(IReadOnlyList<LocalFileEntry> manifest, FileSetLimits limits)
{
    if (manifest.Count > limits.InboundMaxTotalFiles)
    {
        throw new ArgumentException(
            $"File count {manifest.Count} exceeds inboundMaxTotalFiles={limits.InboundMaxTotalFiles}."
        );
    }

    var maxFileSizeBytes = checked(limits.InboundMaxFileSizeInKiloBytes * 1000L);
    var maxTotalSizeBytes = checked(limits.InboundMaxTotalSizeInKiloBytes * 1000L);

    var totalSizeBytes = manifest.Sum(entry => entry.ApiFile.Size);
    if (totalSizeBytes > maxTotalSizeBytes)
    {
        throw new ArgumentException(
            $"Combined file size {totalSizeBytes} bytes exceeds inboundMaxTotalSizeInKiloBytes={limits.InboundMaxTotalSizeInKiloBytes} ({maxTotalSizeBytes} bytes)."
        );
    }

    foreach (var entry in manifest)
    {
        if (entry.ApiFile.Size > maxFileSizeBytes)
        {
            throw new ArgumentException(
                $"File '{entry.ApiFile.Name}' is {entry.ApiFile.Size} bytes and exceeds inboundMaxFileSizeInKiloBytes={limits.InboundMaxFileSizeInKiloBytes} ({maxFileSizeBytes} bytes)."
            );
        }
    }
}

static async Task UploadManifestAsync(
    IFileSetsApi fileSetsApi,
    Guid inboundFileSetId,
    IReadOnlyList<LocalFileEntry> manifest,
    int chunkSizeBytes,
    ILogger logger)
{
    // Reuse a single buffer and stream each file in API-sized chunks.
    Memory<byte> buffer = new byte[chunkSizeBytes];

    foreach (var entry in manifest)
    {
        logger.LogInformation(
            "Uploading file [{Index}] {Name} in chunks of up to {ChunkSizeBytes} bytes...",
            entry.ApiFile.Index, entry.ApiFile.Name, chunkSizeBytes
        );

        long uploadedBytes = 0;
        var chunkCount = 0;

        await using var uploadReadStream = CreateUploadReadStream(entry);

        int idx = 0;
        int bytesRead;

        while ((bytesRead = await ReadChunkAsync(uploadReadStream.Stream, buffer)) > 0)
        {
            chunkCount++;

            var slice = buffer[..bytesRead];

            var uploadResponse = await fileSetsApi.PutFileChunkAsync(
                inboundFileSetId: inboundFileSetId,
                fileIndex: entry.ApiFile.Index,
                chunkIndex: idx,
                body: new FileParameter(slice.AsStream())
            );

            idx += 1;

            if (!uploadResponse.IsSuccessStatusCode)
            {
                uploadResponse.HandleErrorResponse();
            }

            uploadedBytes += bytesRead;
            logger.LogInformation(
                "Chunk {ChunkCount}: sent {BytesRead} bytes ({UploadedBytes}/{TotalSize})",
                chunkCount, bytesRead, uploadedBytes, entry.ApiFile.Size
            );
        }

        logger.LogInformation("Completed upload for {Name}.", entry.ApiFile.Name);
    }
}

static async Task<int> ReadChunkAsync(Stream stream, Memory<byte> buffer)
{
    var totalRead = 0;

    while (totalRead < buffer.Length)
    {
        var bytesRead = await stream.ReadAsync(buffer[totalRead..]);
        if (bytesRead == 0)
        {
            break;
        }

        totalRead += bytesRead;
    }

    return totalRead;
}

sealed record LocalFileEntry(string Path, InboundFileInfo ApiFile);

sealed class UploadReadStream(Stream stream, Func<Stream, ValueTask> disposeAsync)
    : IAsyncDisposable
{
    public Stream Stream { get; } = stream;

    public ValueTask DisposeAsync() => disposeAsync(Stream);
}
