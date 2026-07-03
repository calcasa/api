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
    /**
     * Create a new inbound file set and all its included files. If the type, period, and revision combination already exists, a InboundFileSetAlreadyExistsProblemDetails will be returned. If the file set is not confirmed within 24 hours, it will expire and all it's uploaded ocntents will be deleted.
     *
     * ### Callbacks
     * | Name | Url | Schema |
     * | --- | --- | --- |
     * | inbound-file-set | {configuredWebhookUrl}inbound-file-set | [InboundFileSetWebhookPayload](/api/v1/reference/schemas/InboundFileSetWebhookPayload) |
     * | outbound-file-set | {configuredWebhookUrl}outbound-file-set | [OutboundFileSetWebhookPayload](/api/v1/reference/schemas/OutboundFileSetWebhookPayload) |
     *
     */
    @useAuth(oauth<["api:file-set-inbound:write"]>)
    @route("/inbound")
    @post
    @operationId("CreateInboundFileSet")
    op CreateInboundFileSet(@bodyRoot body: InboundFileSet):
        | InboundFileSet
        | InboundFileSetAlreadyExistsProblemDetails
        | InvalidArgumentProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    @useAuth(oauth<["api:file-set-inbound:read"]>)
    @route("/inbound")
    @get
    @summary("Get all inbound file sets.")
    @operationId("GetInboundFileSets")
    op GetInboundFileSets(
    ): InboundFileSet[] | UnauthorizedProblemDetails | ProblemDetails;

    @useAuth(oauth<["api:file-set-inbound:read"]>)
    @route("/inbound/{inboundFileSetId}")
    @get
    @summary("Get a specific inbound file set by its ID.")
    @operationId("GetInboundFileSetById")
    op GetInboundFileSetById(@format("uuid") inboundFileSetId: string):
        | InboundFileSet
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    @useAuth(oauth<["api:file-set-inbound:write"]>)
    @route("/inbound/{inboundFileSetId}/{fileIndex}")
    @put
    @summary("Upload a specific file chunk for an inbound file set. All chunks must be uploaded in order, if the file is small enough, it can be uploaded in a single request. Total size must not exceed reported file size in the file set.")
    @operationId("PutFileChunk")
    op PutFileChunk(
        @format("uuid") inboundFileSetId: string,
        fileIndex: int32,
        @bodyRoot file: File,
    ):
        | NoContentResponse
        | InvalidArgumentProblemDetails
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    /**
     * Confirm inbound file set after it's has been fully uploaded. This will start the verification of the fileset, when the status is updated the callback will be triggered with the new status. When validation fails, a new file set will need to be created. If the file set is not confirmed within 24 hours, it will expire and all it's uploaded ocntents will be deleted.
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
    @useAuth(oauth<["api:file-set-inbound:write"]>)
    @operationId("ConfirmInboundFileSetById")
    op ConfirmInboundFileSetById(@format("uuid") inboundFileSetId: string):
        | InboundFileSet
        | InboundFileSetAlreadyConfirmedProblemDetails
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    @route("/outbound")
    @get
    @summary("Get all outbound file sets.")
    @useAuth(oauth<["api:file-set-outbound:read"]>)
    @operationId("GetOutboundFileSets")
    op GetOutboundFileSets(
    ): OutboundFileSet[] | UnauthorizedProblemDetails | ProblemDetails;

    @route("/outbound/{outboundFileSetId}")
    @get
    @summary("Get a specific outbound file set by its ID.")
    @useAuth(oauth<["api:file-set-outbound:read"]>)
    @operationId("GetOutboundFileSetById")
    op GetOutboundFileSetById(@format("uuid") outboundFileSetId: string):
        | OutboundFileSet
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    @route("/outbound/{outboundFileSetId}/{fileIndex}")
    @get
    @summary("Get a specific outbound file content by its index within a file set.  Used the Http Range header to request a specific byte range of the file.  If the Range header is not provided, the entire file will be returned.")
    @useAuth(oauth<["api:file-set-outbound:read"]>)
    @operationId("GetOutboundFileByIndex")
    op GetOutboundFile(
        @header range?: string,
        @format("uuid") outboundFileSetId: string,
        fileIndex: int32,
    ):
        | File<"application/octet-stream", Contents = bytes>
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    @route("/outbound/{outboundFileSetId}")
    @delete
    @summary("Delete outbound file set after it's has been correctly received. If a outbound file set is not downloaded and deleted after 48 hours, it will expire and all its contents will be deleted automatically.")
    @useAuth(oauth<["api:file-set-outbound:write"]>)
    @operationId("DeleteOutboundFileSetById")
    op DeleteOutboundFileSetById(@format("uuid") outboundFileSetId: string):
        | NoContentResponse
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;
}
