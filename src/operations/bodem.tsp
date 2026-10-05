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
    * Geeft bodemkwaliteitsgegevens terug voor de locatie van een adres (BAG Nummeraanduiding ID).
    * Het bodemdataobject zal gefilterd terugkomen, afhankelijk van het client_id dat gebruikt is voor de authenticatie.
   */
  @route("/{bagNummeraanduidingId}")
  @get
    @summary("Haal bodemkwaliteitsgegevens op.")
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
