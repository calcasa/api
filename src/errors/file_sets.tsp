import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../errors.tsp";
import "../enums/file_sets.tsp";

using Http;
using OpenAPI;

model FileContentError {
    @key index: int32;

    @example("data.csv")
    name: string;

    /**
     * The expected SHA256 hash of the file contents, represented as an uppercase hexadecimal string.
     */
    @format("hex")
    @pattern("^[A-F0-9]{64}$")
    @example("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855")
    expectedContentHash: string;

    /**
     * The expected file size in bytes.
     */
    expectedFileSize: int64;

    /**
     * The actual SHA256 hash of the file contents, represented as an uppercase hexadecimal string.
     */
    @format("hex")
    @pattern("^[A-F0-9]{64}$")
    @example("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855")
    actualContentHash: string;

    /**
     * The actual file size in bytes.
     */
    actualFileSize: int64;
}

model FileNotice {
    @key index: int32;

    @example("data.csv")
    name: string;

    /**
     * The type of the warning. Short mostly stable strings that can be used to identify the warning type.
     */
    type: string;

    /**
     * A description of the warning to be presented to the user.
     */
    description: string;
}

@error
model InboundFileSetInvalidStateProblemDetails {
    @statusCode statusCode: 422;

    state: InboundFileSetState;

    ...ProblemDetails;
}

@error
model OutboundFileSetInvalidStateProblemDetails {
    @statusCode statusCode: 422;

    state: OutboundFileSetState;

    ...ProblemDetails;
}

@error
model InboundFileSetAlreadyExistsProblemDetails {
    @statusCode statusCode: 409;
    ...ProblemDetails;
}

@error
model LengthRequiredProblemDetails {
    @statusCode statusCode: 411;
    ...ProblemDetails;
}

@error
model ContentTooLargeProblemDetails {
    @statusCode statusCode: 413;

    /**
     * If known the remaining content length in bytes that can be sent to the server. If not known, this property will be null.
     */
    maxContentLength?: int64 | null;

    ...ProblemDetails;
}
