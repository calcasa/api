import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

@useAuth(oauth<["api:adressen:read"]>)
@tag("Adressen")
@route("/adressen")
namespace Adressen {
  /**
   * De Notities zullen leeg blijven voor dit endpoint.
  * Het adresobject zal gefilterd terugkomen, afhankelijk van het client_id dat gebruikt is voor de authenticatie.
   */
  @route("/{bagNummeraanduidingId}")
  @get
  @summary("Adres info op basis van BAG Nummeraanduiding Id.")
  @operationId("GetAdres")
  op GetAdres(
    @doc("Een BAG Nummeraanduiding ID om een adres te specificeren.")
    @path
    bagNummeraanduidingId: int64,
  ):
    | GetAdres200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ProblemDetails;

  /**
   * De notities geven aan of de input al dan niet gewijzigd of onbekend is.
  * De enige velden die echt nodig zijn voor een compleet resultaat zijn de postcode, het huisnummer en de huisnummertoevoeging.
   */
  @route("/zoeken")
  @post
  @summary("Zoek adresinformatie op basis van het opgegeven adres.")
  @operationId("SearchAdres")
  op SearchAdres(
    @doc("Het adresobject dat gebruikt wordt om naar adresinformatie te zoeken.")
    @bodyRoot
    body: Adres,
  ):
    | SearchAdres200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ProblemDetails;
}
