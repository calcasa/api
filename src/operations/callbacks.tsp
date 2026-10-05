import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

@tag("Callbacks")
@route("/callbacks")
namespace Callbacks {
  /**
  * De callbackobjecten zullen gefilterd terugkomen, afhankelijk van het client_id dat gebruikt is voor de authenticatie.
   */
  @useAuth(oauth<["api:callback:read"]>)
  @route("/inschrijvingen")
  @get
  @summary("Haal callbackinschrijvingen op.")
  @operationId("GetNotificationSubscriptions")
  op GetNotificationSubscriptions():
    | GetNotificationSubscriptions200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | ProblemDetails;

  /**
  * De callbackobjecten zullen gefilterd terugkomen, afhankelijk van het client_id dat gebruikt is voor de authenticatie.
   * Als er al een inschrijving bestaat voor dit adres dan wordt deze overschreven.
  * De inschrijvingen worden vanzelf opgeruimd als ze verlopen.
   */
  @useAuth(oauth<["api:callback:write"]>)
  @route("/inschrijvingen")
  @post
  @summary("Maak of werk een callbackinschrijving bij.")
  @operationId("AddOrUpdateCallbackSubscription")
  op AddOrUpdateCallbackSubscription(
    @doc("De te configureren callback inschrijving.")
    @bodyRoot
    body: CallbackInschrijving,
  ):
    | AddOrUpdateCallbackSubscription200Response
    | InvalidArgumentProblemDetails
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | ProblemDetails;

  /**
   * Verwijdert de callbackinschrijving voor de huidige client, het opgegeven adres en optioneel een geldverstrekker.
   */
  @useAuth(oauth<["api:callback:write"]>)
  @route("/inschrijvingen/{bagNummeraanduidingId}")
  @delete
  @summary("Verwijder een callbackinschrijving.")
  @operationId("DeleteNotificationSubscription")
  op DeleteNotificationSubscription(
    @doc("Het BAG Nummeraanduiding ID waar de callback inschrijving voor geldt.")
    @path
    bagNummeraanduidingId: int64,

    @doc("De naam van de geldverstrekker waar de callback inschrijving voor geldt.")
    @query(#{ explode: true })
    geldverstrekker?: string,
  ):
    | DeleteNotificationSubscription204Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ProblemDetails;

  /**
    * Geeft de callbackinschrijving terug voor de huidige client, het opgegeven adres en optioneel een geldverstrekker.
    * Het callbackobject zal gefilterd terugkomen, afhankelijk van het client_id dat gebruikt is voor de authenticatie.
   */
  @useAuth(oauth<["api:callback:read"]>)
  @route("/inschrijvingen/{bagNummeraanduidingId}")
  @get
    @summary("Haal een callbackinschrijving op.")
  @operationId("GetNotificationSubscription")
  op GetNotificationSubscription(
    @doc("Het BAG Nummeraanduiding ID waar de callback inschrijving voor geldt.")
    @path
    bagNummeraanduidingId: int64,

    @doc("De naam van de geldverstrekker waar de callback inschrijving voor geldt.")
    @query(#{ explode: true })
    geldverstrekker?: string,
  ):
    | GetNotificationSubscription200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ProblemDetails;
}
