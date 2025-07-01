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
  @useAuth(oauth<["api:geldverstrekkers:read"]>)
  @route("/{productType}")
  @get
  @summary("Alle geldverstrekkers die te gebruiken zijn voor aanvragen.")
  @operationId("GetGeldverstrekkers")
  op GetGeldverstrekkers(
    /**
     * Een parameter om de lijst te filteren op gesupporte producttypen.
     */
    @path productType: ProductType,
  ): 
  | GetGeldverstrekkers200Response 
  | UnauthorizedProblemDetails 
  | PermissionsDeniedProblemDetails
    | ProblemDetails;
}
