import "@typespec/openapi";
import "@typespec/openapi3";

using OpenAPI;

/**
 * Outbound file set states.
 *
 * | Value | Description |
 * | --- | --- |
 * | `preparing` | File set is being prepared for download. |
 * | `ready` | File set is ready and is waiting for the files to be downloaded. |
 * | `deleted` | File set has been downloaded and has been deleted. |
 * | `expired` | File set has expired and all its contents have been deleted. |
 */
@extension("x-zero-based-enum", true)
enum OutboundFileSetState {
    preparing,
    ready,
    deleted,
    expired,
}

/**
 * Inbound file set states.
 *
 * | Value | Description |
 * | --- | --- |
 * | `created` | File set has just been created and is waiting for the files to be uploaded. |
 * | `uploading` | File set is being uploaded, but not all files have been uploaded yet. |
 * | `verifying` | File set has been fully uploaded and has been confirmed, the file set is in the process of being verified. |
 * | `accepted` | File set has been fully uploaded and has been confirmed, the file set has been verified and is ready for processing. |
 * | `accepted_with_warnings` | File set has been fully uploaded and has been confirmed, the file set has been verified and is ready for processing, but there were some warnings during the verification process. |
 * | `rejected` | File set has been fully uploaded and has been confirmed, but the file set has been rejected during the verification process. There will be errors in the file set that need to be fixed before it can be processed. |
 * | `expired` | File set has expired and all its uploaded contents have been deleted. |
 */
@extension("x-zero-based-enum", true)
enum InboundFileSetState {
    created,
    uploading,
    verifying,
    accepted,
    accepted_with_warnings,
    rejected,
    expired,
}
