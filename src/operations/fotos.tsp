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
  @useAuth(oauth<["api:fotos:read"]>)
  @route("/{id}")
  @get
  @summary("Foto op basis van een foto Id.")
  @operationId("GetFoto")
  op GetFoto(
    /**
     * De Id van een foto, welke onder andere bij waarderingen en referenties teruggestuurd worden.
     */
    @format("uuid") @path id: string,
  ):
    | GetFoto200ImageJpegResponse
    | GetFoto200ImagePngResponse
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ProblemDetails;
}
