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
   * De callback objecten zullen gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.
   */
  @useAuth(oauth<["api:callback:read"]>)
  @route("/inschrijvingen")
  @get
  @summary("Haal de callback inschrijvingen binnen voor deze client.")
  @operationId("GetNotificationSubscriptions")
  op GetNotificationSubscriptions(
  ): 
  | GetNotificationSubscriptions200Response 
  | UnauthorizedProblemDetails 
  | PermissionsDeniedProblemDetails
    | ProblemDetails;

  /**
   * De callback objecten zullen gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.
   * Als er al een inschrijving bestaat voor dit adres dan wordt deze overschreven.
   * De inschrijvingen worden vanzelf opgeruimt als ze verlopen.
   */
  @useAuth(oauth<["api:callback:write"]>)
  @route("/inschrijvingen")
  @post
  @summary("Voeg een callback inschrijving toe (of werk bij) voor de huidige client voor een adres.")
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

  @useAuth(oauth<["api:callback:write"]>)
  @route("/inschrijvingen/{bagNummeraanduidingId}")
  @delete
  @summary("Verwijder de callback inschrijving voor deze client, dit adres en optioneel een geldverstrekker.")
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
   * Het callback object zal gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.
   */
  @useAuth(oauth<["api:callback:read"]>)
  @route("/inschrijvingen/{bagNummeraanduidingId}")
  @get
  @summary("Haal de callback inschrijving op voor deze client, dit adres en eventueel opgegeven geldverstrekker.")
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
