import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models/file_sets.tsp";
import "../errors/file_sets.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

@tag("FileSets")
@route("/file-sets")
namespace FileSets {
    @useAuth(oauth<["api:file-set:inbound:read"]>)
    @route("/limits")
    @get
    @summary("Get file set limits.")
    @operationId("GetFileSetLimits")
    op GetFileSetLimits():
        | FileSetLimits
        | UnauthorizedProblemDetails
        | ProblemDetails;

    /**
     * Create a new inbound file set and all its included files. If the type, period, and revision combination already exists, an InboundFileSetAlreadyExistsProblemDetails will be returned. If the file set is not confirmed within 24 hours, it will expire and all its uploaded contents will be deleted.
     *
     * ### Callbacks
     * | Name | Url | Schema |
     * | --- | --- | --- |
     * | inbound-file-set | {configuredWebhookUrl}inbound-file-set | [InboundFileSetWebhookPayload](/api/v1/reference/schemas/InboundFileSetWebhookPayload) |
     * | outbound-file-set | {configuredWebhookUrl}outbound-file-set | [OutboundFileSetWebhookPayload](/api/v1/reference/schemas/OutboundFileSetWebhookPayload) |
     *
     */
    @useAuth(oauth<["api:file-set:inbound:write"]>)
    @route("/inbound")
    @post
    @summary("Create a new inbound file set.")
    @operationId("CreateInboundFileSet")
    op CreateInboundFileSet(@bodyRoot body: CreateInboundFileSetRequest):
        | InboundFileSet
        | InboundFileSetAlreadyExistsProblemDetails
        | InvalidArgumentProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    /**
     * This will not include the file details, only the metadata of the file set. Use the GetInboundFileSetById operation to get the details of a specific file set.
     */
    @useAuth(oauth<["api:file-set:inbound:read"]>)
    @route("/inbound")
    @get
    @summary("Get all inbound file sets.")
    @operationId("GetInboundFileSets")
    op GetInboundFileSets():
        | InboundFileSet[]
        | UnauthorizedProblemDetails
        | ProblemDetails;

    @useAuth(oauth<["api:file-set:inbound:read"]>)
    @route("/inbound/{inboundFileSetId}")
    @get
    @summary("Get a specific inbound file set by its ID.")
    @operationId("GetInboundFileSetById")
    op GetInboundFileSetById(@format("uuid") inboundFileSetId: string):
        | InboundFileSet
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    /**
     * Upload a specific file chunk for an inbound file set. All chunks must be uploaded in order, if the file is small enough, it can be uploaded in a single request. Total size must not exceed reported file size in the file set.
     */
    @useAuth(oauth<["api:file-set:inbound:write"]>)
    @route("/inbound/{inboundFileSetId}/{fileIndex}")
    @put
    @summary("Upload a specific file chunk for an inbound file set.")
    @operationId("PutFileChunk")
    op PutFileChunk(
        @format("uuid") inboundFileSetId: string,
        fileIndex: int32,
        @header contentEncoding?: "br" | "gzip" | "deflate" | "identity",
        @bodyRoot file: File<"application/octet-stream", Contents = bytes>
    ):
        | NoContentResponse
        | InvalidArgumentProblemDetails
        | LengthRequiredProblemDetails
        | ContentTooLargeProblemDetails
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    /**
     * Confirm an inbound file set after it has been fully uploaded. This will start verification of the file set. When the status is updated, the callback will be triggered with the new status. When validation fails, a new file set must be created. If the file set is not confirmed within 24 hours, it will expire and all its uploaded contents will be deleted.
     *
     * ### Callbacks
     * | Name | Url | Schema |
     * | --- | --- | --- |
     * | inbound-file-set | {configuredWebhookUrl}inbound-file-set | [InboundFileSetWebhookPayload](/api/v1/reference/schemas/InboundFileSetWebhookPayload) |
     * | outbound-file-set | {configuredWebhookUrl}outbound-file-set | [OutboundFileSetWebhookPayload](/api/v1/reference/schemas/OutboundFileSetWebhookPayload) |
     *
     */
    @route("/inbound/{inboundFileSetId}")
    @put
    @useAuth(oauth<["api:file-set:inbound:write"]>)
    @summary("Confirm an inbound file set after it has been fully uploaded.")
    @operationId("ConfirmInboundFileSetById")
    op ConfirmInboundFileSetById(@format("uuid") inboundFileSetId: string):
        | InboundFileSet
        | InboundFileSetInvalidStateProblemDetails
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    /**
     * This will not include the file details, only the metadata of the file set. Use the GetOutboundFileSetById operation to get the details of a specific file set.
     */
    @route("/outbound")
    @get
    @summary("Get all outbound file sets.")
    @useAuth(oauth<["api:file-set:outbound:read"]>)
    @operationId("GetOutboundFileSets")
    op GetOutboundFileSets():
        | OutboundFileSet[]
        | UnauthorizedProblemDetails
        | ProblemDetails;

    @route("/outbound/{outboundFileSetId}")
    @get
    @summary("Get a specific outbound file set by its ID.")
    @useAuth(oauth<["api:file-set:outbound:read"]>)
    @operationId("GetOutboundFileSetById")
    op GetOutboundFileSetById(@format("uuid") outboundFileSetId: string):
        | OutboundFileSet
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    /**
     * Get a specific outbound file content by its index within a file set. Use the Http Range header to request a specific byte range of the file and Accept-Encoding to specify the compression. If the Range header is not provided, the entire file will be returned.
     */
    @route("/outbound/{outboundFileSetId}/{fileIndex}")
    @get
    @summary("Get a specific outbound file content by its index within a file set.")
    @useAuth(oauth<["api:file-set:outbound:read"]>)
    @operationId("GetOutboundFileByIndex")
    op GetOutboundFile(
        @header range?: string,
        @header acceptEncoding?: string,
        @format("uuid") outboundFileSetId: string,
        fileIndex: int32,
    ):
        | File<"application/octet-stream", Contents = bytes>
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    /**
     * Delete an outbound file set after it has been correctly received. If an outbound file set is not downloaded and deleted within 48 hours, it will expire and all its contents will be deleted automatically.
     */
    @route("/outbound/{outboundFileSetId}")
    @delete
    @summary("Delete an outbound file set after it has been correctly received. If an outbound file set is not downloaded and deleted within 48 hours, it will expire and all its contents will be deleted automatically.")
    @useAuth(oauth<["api:file-set:outbound:write"]>)
    @operationId("DeleteOutboundFileSetById")
    op DeleteOutboundFileSetById(@format("uuid") outboundFileSetId: string):
        | NoContentResponse
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;
}
