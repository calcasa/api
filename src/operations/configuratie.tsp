import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

@tag("Configuratie")
@route("/configuratie")
namespace Configuratie {
  /**
   * Het callback object zal gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.
   */
  @useAuth(oauth<["api:configuratie:read"]>)
  @route("/callbacks")
  @get
  @summary("Haal de geconfigureerde callback URL's op voor de huidige client.")
  @operationId("GetCallbacks")
  op GetCallbacks(
  ): 
  | GetCallbacks200Response 
  | UnauthorizedProblemDetails 
  | PermissionsDeniedProblemDetails
    | ProblemDetails;

  /**
   * Indien er al een callback geconfigureerd is voor de opgegeven versie zal deze overschreven worden. Bij het aanroepen van de callback URL zal de CallbackName achter de URL toegevoegd worden. Een lege string of null verwijdert de geconfigureerde URL.
   */
  @useAuth(oauth<["api:configuratie:write"]>)
  @route("/callbacks")
  @post
  @summary("Configureer callback URL voor een specifieke API versie voor de huidige client.")
  @operationId("UpdateCallbacks")
  op UpdateCallbacks(@bodyRoot body: Callback):
    | UpdateCallbacks200Response
    | InvalidArgumentProblemDetails
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | ProblemDetails;
}
