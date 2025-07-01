import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

@useAuth(oauth<["api:bestemmingsplannen:read"]>)
@tag("Bestemmingsplannen")
@route("/bestemmingsplannen")
namespace Bestemmingsplannen {
  /**
   * Het bodemdata object zal gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.
   */
  @route("/{bagNummeraanduidingId}")
  @get
  @summary("Gegevens over de bestemmingsplannen op de locatie van een adres (BAG Nummeraanduiding ID).")
  @operationId("GetBestemmingById")
  op GetBestemmingById(
    @doc("Een BAG Nummeraanduiding ID om een adres te specificeren.")
    @path
    bagNummeraanduidingId: int64,
  ):
    | GetBestemmingById200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ProblemDetails;
}
