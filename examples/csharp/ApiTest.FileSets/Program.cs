using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Threading.Tasks;
using ApiTest.Shared;
using Calcasa.Api.Api;
using Calcasa.Api.Client;
using Calcasa.Api.Model;
using Microsoft.Extensions.DependencyInjection;
using MimeKit;
using FileInfo = Calcasa.Api.Model.FileInfo;

const string FileSetType = "test-file-set";

// Shared bootstrap: loads .env values and configures OAuth + API host.
var host = ExamplesConfiguration.CreateApiHost(args);
var fileSetDirectory = ExamplesConfiguration.GetRequiredEnvironmentVariable("CALCASA_TEST_FILE_SET_PATH");

if (!Directory.Exists(fileSetDirectory))
{
    throw new DirectoryNotFoundException($"Directory {fileSetDirectory} not found.");
}

Console.WriteLine($"Found test file set path: {fileSetDirectory}");

var fileSetRevision = GetFileSetRevision();

// Build a deterministic local manifest first so file metadata and order are stable.
var fs = host.Services.GetRequiredService<IFileSetsApi>();
var manifest = BuildFileManifest(fileSetDirectory);
PrintManifest(manifest);

// Read inbound limits and validate before uploading any file data.
var limitsResponse = await fs.GetFileSetLimitsAsync();
if (!limitsResponse.TryOk(out var limitsResult) || limitsResult is null)
{
    limitsResponse.HandleErrorResponse();
    throw new InvalidOperationException("Failed to retrieve file set limits.");
}

var limits = limitsResult;

PrintLimits(limits);
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

Console.WriteLine(
    $"Using file set identity type={FileSetType}, revision={fileSetRevision}, period={createRequest.Period}."
);

var inboundFileSetResponse = await fs.CreateInboundFileSetAsync(createRequest);
if (!inboundFileSetResponse.TryOk(out var inboundFileSetResult) || inboundFileSetResult is null)
{
    inboundFileSetResponse.HandleErrorResponse();
    throw new InvalidOperationException("Failed to create inbound file set.");
}

var inboundFileSet = inboundFileSetResult;

var inboundFileSetId = inboundFileSet.Id;
Console.WriteLine($"Created inbound file set {inboundFileSetId} with state {inboundFileSet.State}.");

// Upload all files chunk-by-chunk, then confirm to start server-side verification.
await UploadManifestAsync(fs, inboundFileSetId, manifest, chunkSizeBytes);

var confirmedFileSetResponse = await fs.ConfirmInboundFileSetByIdAsync(inboundFileSetId);
if (!confirmedFileSetResponse.TryOk(out var confirmedFileSetResult) || confirmedFileSetResult is null)
{
    confirmedFileSetResponse.HandleErrorResponse();
    throw new InvalidOperationException("Failed to confirm inbound file set.");
}

var confirmedFileSet = confirmedFileSetResult;

Console.WriteLine($"Confirmed inbound file set {confirmedFileSet.Id} with state {confirmedFileSet.State}.");

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
        var apiFile = new FileInfo(
            index: index,
            name: relativeName,
            contentHash: CalculateSha256(filePath),
            size: fileInfo.Length,
            contentType: contentType
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

static void PrintManifest(IReadOnlyList<LocalFileEntry> manifest)
{
    Console.WriteLine($"Preparing {manifest.Count} files for upload:");
    foreach (var entry in manifest)
    {
        Console.WriteLine(
            $"- [{entry.ApiFile.Index}] {entry.ApiFile.Name} ({entry.ApiFile.Size} bytes, {entry.ApiFile.ContentType})"
        );
    }
}

static void PrintLimits(FileSetLimits limits)
{
     Console.WriteLine(
        $"Inbound limits: maxFiles={limits.InboundMaxTotalFiles}, " +
        $"maxFileSize={limits.InboundMaxFileSizeInKiloBytes * 1000L} bytes, " +
        $"maxTotalSize={limits.InboundMaxTotalSizeInKiloBytes * 1000L} bytes, " +
        $"maxChunkSize={limits.InboundMaxCompressedChunkSizeInKiloBytes * 1000L} bytes, " +
        $"ttl={limits.InboundTtlInSeconds} seconds"
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
    int chunkSizeBytes)
{
    // Reuse a single buffer and stream each file in API-sized chunks.
    var buffer = new byte[chunkSizeBytes];

    foreach (var entry in manifest)
    {
        Console.WriteLine(
            $"Uploading file [{entry.ApiFile.Index}] {entry.ApiFile.Name} in chunks of up to {chunkSizeBytes} bytes..."
        );

        long uploadedBytes = 0;
        var chunkCount = 0;

        await using var fileStream = File.OpenRead(entry.Path);
        int bytesRead;
        while ((bytesRead = await fileStream.ReadAsync(buffer.AsMemory(0, buffer.Length))) > 0)
        {
            chunkCount++;

            await using var chunkStream = new MemoryStream(buffer, 0, bytesRead, writable: false);
            var uploadResponse = await fileSetsApi.PutFileChunkAsync(
                inboundFileSetId: inboundFileSetId,
                fileIndex: entry.ApiFile.Index,
                body: new FileParameter(chunkStream),
                contentEncoding: "identity"
            );

            if (!uploadResponse.IsSuccessStatusCode)
            {
                uploadResponse.HandleErrorResponse();
            }

            uploadedBytes += bytesRead;
            Console.WriteLine(
                $"  chunk {chunkCount}: sent {bytesRead} bytes ({uploadedBytes}/{entry.ApiFile.Size})"
            );
        }

        Console.WriteLine($"Completed upload for {entry.ApiFile.Name}.");
    }
}

sealed record LocalFileEntry(string Path, FileInfo ApiFile);
