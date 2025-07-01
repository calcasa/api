import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

@tag("Facturen")
@route("/facturen")
namespace Facturen {
  @useAuth(oauth<["api:facturen:read"]>)
  @route("/{id}")
  @get
  @summary("Factuur op basis van een waardering Id.")
  @operationId("GetFactuur")
  op GetFactuur(
    /**
     * De Id van een waardering.
     */
    @format("uuid") @path id: string,
  ):
    | GetFactuur200ApplicationPdfResponse
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ProblemDetails;
}
