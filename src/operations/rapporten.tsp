import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

@tag("Rapporten")
@route("/rapporten")
namespace Rapporten {
  @useAuth(oauth<["api:rapporten:read"]>)
  @route("/{id}")
  @get
  @summary("Rapport op basis van waardering Id.")
  @operationId("GetRapport")
  op GetRapport(
    /**
     * De Id van een waardering.
     */
    @format("uuid") @path id: string,
  ):
    | GetRapport200ApplicationPdfResponse
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ProblemDetails;
}
