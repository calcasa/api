import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "./problem_details.tsp";

using Http;
using OpenAPI;

/**
 * Provided credentials have expired or request was unauthenticated.
 */
@error
model ProblemResponse401 {
  @statusCode statusCode: 401;
  @bodyRoot body: ProblemDetails;
}

/**
 * Client does not have permission to perform this action.
 *
 * Permission denied
 */
@error
model ProblemResponse403 {
  @statusCode statusCode: 403;
  @bodyRoot body: PermissionsDeniedProblemDetails;
}

/**
 * Business rules not passed.
 *
 *
 */
@error
model ProblemResponse406 {
  @statusCode statusCode: 406;
  @bodyRoot body: BusinessRulesProblemDetails;
}

/**
 * NotFoundProblemDetails Entity not found.
 * Could not find valuation.
 *
 *
 */
@error
model ProblemResponse404 {
  @statusCode statusCode: 404;
  @bodyRoot body: NotFoundProblemDetails;
}

/**
 * Request could not be processed.
 *
 *
 */
@error
model ProblemResponse422 {
  @statusCode statusCode: 422;
  @bodyRoot body: ValidationProblemDetails;
}
