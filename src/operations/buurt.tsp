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
    * Geeft gegevens terug over een buurt en de bijbehorende wijk, gemeente en land.
    * Het omgevingsdataobject zal gefilterd terugkomen, afhankelijk van het client_id dat gebruikt is voor de authenticatie.
   */
  @route("/{buurtCode}")
  @get
    @summary("Haal buurtgegevens op.")
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
