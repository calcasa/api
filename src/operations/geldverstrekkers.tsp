import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

@tag("Geldverstrekkers")
@route("/geldverstrekkers")
namespace Geldverstrekkers {
  /**
   * Geeft alle geldverstrekkers terug die voor aanvragen kunnen worden gebruikt.
   */
  @useAuth(oauth<["api:geldverstrekkers:read"]>)
  @route("/{productType}")
  @get
  @summary("Haal geldverstrekkers op.")
  @operationId("GetGeldverstrekkers")
  op GetGeldverstrekkers(
    /**
    * Een parameter om de lijst te filteren op ondersteunde producttypen.
     */
    @path productType: ProductType,
  ):
    | GetGeldverstrekkers200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | ProblemDetails;
}
