import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

#deprecated "These operations are deprecated and will be removed in a future version. The fundering data is now included with the Waardering object."
@tag("Funderingen")
@route("/funderingen")
namespace Funderingen {
  /**
  * Het funderingsdataobject zal gefilterd terugkomen, afhankelijk van het client_id dat gebruikt is voor de authenticatie.
   */
  @useAuth(oauth<["api:funderingen:read"]>)
  @route("/{bagNummeraanduidingId}")
  @get
  @summary("Gegevens over de fundering op de locatie van een adres (BAG Nummeraanduiding ID).")
  @operationId("GetFunderingById")
  op GetFunderingById(
    /**
     * Een BAG Nummeraanduiding ID om een adres te specificeren.
     */
    @path bagNummeraanduidingId: int64,
  ):
    | GetFunderingById200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ProblemDetails;
}
