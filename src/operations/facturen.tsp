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
  /**
   * Geeft de PDF-factuur terug voor een waardering.
   */
  @useAuth(oauth<["api:facturen:read"]>)
  @route("/{id}")
  @get
  @summary("Haal een factuur op.")
  @operationId("GetFactuur")
  op GetFactuur(
    /**
     * De Id van een waardering.
     */
    @format("uuid") @path id: string,
  ):
    | File<"application/pdf", Contents = bytes>
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ProblemDetails;
}
