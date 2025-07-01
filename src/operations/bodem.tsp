import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

@useAuth(oauth<["api:bodem:read"]>)
@tag("Bodem")
@route("/bodem")
namespace Bodem {
  /**
   * Het bodemdata object zal gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.
   */
  @route("/{bagNummeraanduidingId}")
  @get
  @summary("Gegevens over de bodemkwaliteit op de locatie van een adres (BAG Nummeraanduiding ID).")
  @operationId("GetBodemById")
  op GetBodemById(
    @doc("Een BAG Nummeraanduiding ID om een adres te specificeren.")
    @path
    bagNummeraanduidingId: int64,
  ):
    | GetBodemById200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ProblemDetails;
}
