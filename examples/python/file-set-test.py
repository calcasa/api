from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import mimetypes
import os
from pathlib import Path
from typing import Iterator
from uuid import UUID

from calcasa.api import CompressionType, InboundFileInfo
from calcasa.api.api.file_sets_api import FileSetsApi
from calcasa.api.models.create_inbound_file_set_request import CreateInboundFileSetRequest
from calcasa.api.models.file_set_limits import FileSetLimits

from common import BrotliCompressReadStream, GzipCompressReadStream, create_api_client, get_required_env, load_example_environment
from brotli import MODE_GENERIC, MODE_TEXT


FILE_SET_TYPE = "test-file-set"
# In production use consecutive revisions, 0, 1, 2, 3, ... for each new file set. Here we use a time stamp for easy testing.
FILE_SET_REVISION = int(
    os.environ.get("CALCASA_TEST_FILE_SET_REVISION", str(int(datetime.now(timezone.utc).timestamp())))
)


@dataclass(frozen=True)
class LocalFileEntry:
    path: Path
    api_file: InboundFileInfo


def calculate_sha256(file_path: Path) -> str:
    digest = hashlib.sha256()

    with file_path.open("rb") as handle:
        while True:
            chunk = handle.read(1024 * 1024)
            if not chunk:
                break

            digest.update(chunk)

    return digest.hexdigest().upper()


def build_file_manifest(root_path: Path) -> list[LocalFileEntry]:
    # Build a deterministic manifest so indices and relative names are stable across retries.
    files = sorted(file_path for file_path in root_path.rglob("*") if file_path.is_file())
    manifest: list[LocalFileEntry] = []

    for index, file_path in enumerate(files):
        relative_name = file_path.relative_to(root_path).as_posix()
        api_file = InboundFileInfo(
            index=index,
            name=relative_name,
            contentHash=calculate_sha256(file_path),
            size=file_path.stat().st_size,
            contentType=mimetypes.guess_type(file_path)[0] or "application/octet-stream",
            compression=CompressionType.GZIP, # The server will decompress automatically. All chunks are concatenated and then decompressed.
        )
        manifest.append(LocalFileEntry(path=file_path, api_file=api_file))

    return manifest


def validate_manifest_against_limits(
    manifest: list[LocalFileEntry], limits: FileSetLimits
) -> None:
    if not manifest:
        raise ValueError("The test file set directory does not contain any files to upload.")

    max_total_files = limits.inbound_max_total_files
    if len(manifest) > max_total_files:
        raise ValueError(
            f"File count {len(manifest)} exceeds inboundMaxTotalFiles={max_total_files}."
        )

    max_file_size_bytes = limits.inbound_max_file_size_in_kilo_bytes * 1000
    max_total_size_bytes = limits.inbound_max_total_size_in_kilo_bytes * 1000

    total_size_bytes = sum(entry.api_file.size for entry in manifest)
    if total_size_bytes > max_total_size_bytes:
        raise ValueError(
            "Combined file size "
            f"{total_size_bytes} bytes exceeds inboundMaxTotalSizeInKiloBytes="
            f"{limits.inbound_max_total_size_in_kilo_bytes} ({max_total_size_bytes} bytes)."
        )

    for entry in manifest:
        if entry.api_file.size > max_file_size_bytes:
            raise ValueError(
                f"File '{entry.api_file.name}' is {entry.api_file.size} bytes and exceeds "
                "inboundMaxFileSizeInKiloBytes="
                f"{limits.inbound_max_file_size_in_kilo_bytes} ({max_file_size_bytes} bytes)."
            )

def is_text_file(content_type: str) -> bool:
    return content_type.startswith("text/") or "json" in content_type or "yaml" in content_type

def iter_file_chunks(entry: LocalFileEntry, chunk_size_bytes: int) -> Iterator[tuple[int, bytes]]:
    idx = 0
    with entry.path.open("rb") as handle:
        if entry.api_file.compression == CompressionType.GZIP:
            # You can of course also read already compressed Gzip files from disk and send them as-is to the server. Or you can just run gzip cli to stdout etc.
            compressed_stream = GzipCompressReadStream(fileobj=handle)
        elif entry.api_file.compression == CompressionType.BROTLI:
            # You can of course also read already compressed Brotli files from disk and send them as-is to the server. Or you can just run brotli cli to stdout etc.
            mode = MODE_TEXT if is_text_file(entry.api_file.content_type) else MODE_GENERIC
            compressed_stream = BrotliCompressReadStream(fileobj=handle, mode=mode) # compresslevel 2 seems to be most optimal for speed vs compression.
        else:
            compressed_stream = handle
        while True:
            chunk = compressed_stream.read(chunk_size_bytes)
            if not chunk:
                break
            yield idx, chunk
            idx += 1


def print_manifest(manifest: list[LocalFileEntry]) -> None:
    print(f"Preparing {len(manifest)} files for upload:")
    for entry in manifest:
        print(
            f"- [{entry.api_file.index}] {entry.api_file.name} "
            f"({entry.api_file.size} bytes, {entry.api_file.content_type})"
        )


def upload_manifest(
    api: FileSetsApi,
    inbound_file_set_id: UUID,
    manifest: list[LocalFileEntry],
    chunk_size_bytes: int,
) -> None:
    # Stream each file in server-approved chunk sizes instead of loading all bytes in memory.
    for entry in manifest:
        print(
            f"Uploading file [{entry.api_file.index}] {entry.api_file.name} "
            f"in chunks of up to {chunk_size_bytes} bytes..."
        )

        uploaded_bytes = 0
        chunk_count = 0

        for idx, chunk in iter_file_chunks(entry, chunk_size_bytes):
            chunk_count += 1
            api.put_file_chunk(
                inbound_file_set_id=inbound_file_set_id,
                file_index=entry.api_file.index,
                chunk_index=idx,
                body=chunk
            )
            uploaded_bytes += len(chunk)
            print(
                f"  chunk {chunk_count}: sent {len(chunk)} bytes "
                f"({uploaded_bytes}/{entry.api_file.size}) "
            )

        print(f"Completed upload for {entry.api_file.name}.")

load_example_environment()

# Shared setup: validates required env values and configures OAuth + API client.
api_client = create_api_client(extra_required_env=["CALCASA_TEST_FILE_SET_PATH"])

file_sets_api = FileSetsApi(api_client)

file_set_path = Path(get_required_env("CALCASA_TEST_FILE_SET_PATH"))

if not file_set_path.exists() or not file_set_path.is_dir():
    raise Exception(f"Test file set path does not exist or is not a directory: {file_set_path}")
else:
    print(f"Found test file set path: {file_set_path}")

manifest = build_file_manifest(file_set_path)
print_manifest(manifest)

# Guardrails first: check server limits before creating or uploading the file set.
limits = file_sets_api.get_file_set_limits()
print(
    "Inbound limits: "
    f"maxFiles={limits.inbound_max_total_files}, "
    f"maxFileSize={limits.inbound_max_file_size_in_kilo_bytes * 1000} bytes, "
    f"maxTotalSize={limits.inbound_max_total_size_in_kilo_bytes * 1000} bytes, "
    f"maxChunkSize={limits.inbound_max_compressed_chunk_size_in_kilo_bytes * 1000} bytes, "
    f"ttl={limits.inbound_ttl_in_seconds} seconds"
)

validate_manifest_against_limits(manifest, limits)

chunk_size_bytes = limits.inbound_max_compressed_chunk_size_in_kilo_bytes * 1000
if chunk_size_bytes <= 0:
    raise ValueError(
        "GetFileSetLimits returned an invalid inboundMaxCompressedChunkSizeInKiloBytes value."
    )

create_request = CreateInboundFileSetRequest(
    type=FILE_SET_TYPE,
    revision=FILE_SET_REVISION,
    period=datetime.now(timezone.utc).date(),
    files=[entry.api_file for entry in manifest],
)

print(
    f"Using file set identity type={FILE_SET_TYPE}, revision={FILE_SET_REVISION}, "
    f"period={create_request.period}."
)

inbound_file_set = file_sets_api.create_inbound_file_set(create_request)
inbound_file_set_id = UUID(str(inbound_file_set.id))
print(
    f"Created inbound file set {inbound_file_set_id} "
    f"with state {inbound_file_set.state}."
)

upload_manifest(file_sets_api, inbound_file_set_id, manifest, chunk_size_bytes)

# Confirm marks upload complete and starts server-side verification.
confirmed_file_set = file_sets_api.confirm_inbound_file_set_by_id(inbound_file_set_id)
print(
    f"Confirmed inbound file set {confirmed_file_set.id} "
    f"with state {confirmed_file_set.state}."
)
