import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../errors.tsp";
import "../enums/file_sets.tsp";

using Http;
using OpenAPI;

model FileError {
    @key index: int32;

    @example("data.csv")
    name: string;

    /**
     * The expected SHA256 hash of the file contents, represented as an uppercase hexadecimal string.
     */
    @format("hex")
    @pattern("^[A-F0-9]{64}$")
    @example("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855")
    expectedSha256hash: string;

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
    actualSha256hash: string;

    /**
     * The actual file size in bytes.
     */
    actualFileSize: int64;
}

model FileWarning {
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
model InboundFileSetAlreadyConfirmedProblemDetails {
    @statusCode statusCode: 409;
    ...ProblemDetails;
}

@error
model InboundFileSetAlreadyExistsProblemDetails {
    @statusCode statusCode: 409;
    ...ProblemDetails;
}
