import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "./enums.tsp";
using Http;
using OpenAPI;

/**
 * Base error response model as defined in RFC 7807 Problem Details for HTTP APIs.
 */
@error
model ProblemDetails {
  @header("content-type") contentType: "application/problem+json";

  /**
   * A URI reference [RFC3986] that identifies the problem type.
   */
  type?: string | null;

  /**
   * A short, human-readable summary of the problem type.
   */
  title?: string | null;

  /**
   * The HTTP status code for this occurrence of the problem.
   */
  status?: int32 | null;

  /**
   * A human-readable explanation specific to this occurrence of the problem.
   */
  detail?: string | null;

  /**
   * A URI reference that identifies the specific occurrence of the problem.
   */
  instance?: string | null;
}

@error
model UnauthorizedProblemDetails {
  ...UnauthorizedResponse;
  ...ProblemDetails;
}

@error
model NotFoundProblemDetails {
  ...NotFoundResponse;

  @example("entity:1234123")
  entity?: string;

  ...ProblemDetails;
}

@error
model PermissionsDeniedProblemDetails {
  @statusCode statusCode: 403;

  @example("entity:read")
  requiredPermission?: string;

  ...ProblemDetails;
}

/**
 * Resource exhausted.
 */
@error
model ResourceExhaustedProblemDetails {
  @statusCode statusCode: 402;

  @example("entity:1234123")
  resource?: string;

  ...ProblemDetails;
}

@error
model ValidationProblemDetails {
  @statusCode statusCode: 422;
  errors?: Record<string[]>;
  ...ProblemDetails;
}

@error
model BusinessRulesProblemDetails {
  @statusCode statusCode: 406;
  businessRulesCode?: BusinessRulesCode;
  ...ProblemDetails;
}

/**
 * Invalid argument was provided.
 *
 *
 */
@error
model InvalidArgumentProblemDetails {
  @statusCode statusCode: 400;
  paramName?: string;
  ...ProblemDetails;
}
