import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

@tag("Fotos")
@route("/fotos")
namespace Fotos {
  /**
   * Geeft een foto terug die onder andere bij waarderingen en referenties wordt gebruikt.
   */
  @useAuth(oauth<["api:fotos:read"]>)
  @route("/{id}")
  @get
  @summary("Haal een foto op.")
  @operationId("GetFoto")
  op GetFoto(
    /**
     * De Id van een foto, welke onder andere bij waarderingen en referenties teruggestuurd worden.
     */
    @format("uuid") @path id: string,
  ):
    | File<"image/jpeg" | "image/png", Contents = bytes>
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ProblemDetails;
}
