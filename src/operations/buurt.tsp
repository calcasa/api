import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

@useAuth(oauth<["api:buurt:read"]>)
@tag("Buurt")
@route("/buurt")
namespace Buurt {
  /**
   * Het omgevingdata object zal gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.
   */
  @route("/{buurtCode}")
  @get
  @summary("Gegevens over een buurt en de wijk, gemeente en land waarin deze buurt gesitueerd is.")
  @operationId("GetBuurt")
  op GetBuurt(
    @doc("Een CBS buurt code.")
    @path
    buurtCode: string,
  ):
    | GetBuurt200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ProblemDetails;
}
