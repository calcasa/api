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
  /**
   * Geeft het PDF-rapport terug voor een waardering.
   */
  @useAuth(oauth<["api:rapporten:read"]>)
  @route("/{id}")
  @get
  @summary("Haal een rapport op.")
  @operationId("GetRapport")
  op GetRapport(
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
