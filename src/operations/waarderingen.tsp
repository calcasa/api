import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

@tag("Waarderingen")
@route("/waarderingen")
namespace Waarderingen {
  @doc("Het waardering object zal gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.")
  @useAuth(oauth<["api:waarderingen:read"]>)
  @route("/{id}")
  @get
  @summary("Waardering op basis van Id.")
  @operationId("GetWaardering")
  op GetWaardering(
    /**
     * De waardering Id in de vorm van een UUID.
     */
    @format("uuid") @path id: string,
  ):
    | GetWaardering200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ValidationProblemDetails
    | ProblemDetails;

  /**
   * Het waardering object zal gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.
   *
   * Op dit moment kan alleen de waarderingsstatus gepatcht worden.
   * Dit endpoint kan gebruikt worden om een waarderingsinitialisatie te bevestigen.
   *
   * ### Callbacks
   * | Name | Url | Schema |
   * | --- | --- | --- |
   * | waardering | {configuredWebhookUrl}waardering | [WaarderingWebhookPayload](/api/v1/reference/schemas/WaarderingWebhookPayload) |
   * | deel-waardering | {configuredWebhookUrl}deel-waardering | [DeelWaarderingWebhookPayload](/api/v1/reference/schemas/DeelWaarderingWebhookPayload) |
   *
   */
  @useAuth(oauth<["api:waarderingen:patch"]>)
  @route("/{id}")
  @patch(#{ implicitOptionality: false })
  @summary("Patcht een waardering.")
  @operationId("PatchWaarderingen")
  op PatchWaarderingen(
    /**
     * De waardering Id in de vorm van een UUID.
     */
    @format("uuid") @path id: string,

    @header contentType: "application/json-patch+json",
    @bodyRoot body: JsonPatchDocument,
  ):
    | PatchWaarderingen200Response
    | InvalidArgumentProblemDetails
    | UnauthorizedProblemDetails
    | ResourceExhaustedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ValidationProblemDetails
    | ProblemDetails;

  @doc("Het waardering object zal gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.")
  @useAuth(oauth<["api:waarderingen:ontwikkeling"]>)
  @route("/{id}/ontwikkeling")
  @get
  @summary("Waardering ontwikkeling op basis van waardering Id.")
  @operationId("GetWaarderingOntwikkeling")
  op GetWaarderingOntwikkeling(
    /**
     * De waardering Id in de vorm van een UUID.
     */
    @format("uuid") @path id: string,
  ):
    | GetWaarderingOntwikkeling200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | NotFoundProblemDetails
    | ValidationProblemDetails
    | ProblemDetails;

  @doc("""
    Het waardering object zal gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.
    Alle items kunnen gebruikt worden voor het zoeken, ProductType en BagNummeraanduidingId zijn verplicht.  
    """)
  @useAuth(oauth<["api:waarderingen:read"]>)
  @route("/zoeken")
  @post
  @summary("Zoek waardering op basis van input parameters.")
  @operationId("SearchWaarderingen")
  op SearchWaarderingen(@bodyRoot body: WaarderingZoekParameters):
    | SearchWaarderingen200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | ValidationProblemDetails
    | ProblemDetails;

  /**
   * Het waardering object zal gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.
   * Nadat de waardering aangemaakt is zal deze bevestigd moeten worden. De BagNummeraanduidingId en ProductType velden zijn (ten minste) verplicht.
   *
   * ### Callbacks
   * | Name | Url | Schema |
   * | --- | --- | --- |
   * | waardering | {configuredWebhookUrl}waardering | [WaarderingWebhookPayload](/api/v1/reference/schemas/WaarderingWebhookPayload) |
   * | deel-waardering | {configuredWebhookUrl}deel-waardering | [DeelWaarderingWebhookPayload](/api/v1/reference/schemas/DeelWaarderingWebhookPayload) |
   *
   */
  @useAuth(oauth<["api:waarderingen:create"]>)
  @route("")
  @post
  @summary("Creërt een waardering.")
  @operationId("CreateWaardering")
  op CreateWaardering(@bodyRoot body: WaarderingInputParameters):
    | CreateWaardering200Response
    | InvalidArgumentProblemDetails
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | BusinessRulesProblemDetails
    | ValidationProblemDetails
    | ProblemDetails;

  /**
   * Geeft de mogelijke en afgekeurde producten terug voor een waardering op basis van de input parameters. Het BagNummeraanduidingId veld is (ten minste) verplicht. Als er geen enkel product geconfigureerd komt er een exception terug.
   */
  @useAuth(oauth<["api:waarderingen:create"]>)
  @route("check")
  @post
  @summary("Controleert mogelijke producten.")
  @operationId("CheckProducten")
  op CheckProducten(@bodyRoot body: ProductCheckParameters):
    | CheckProducten200Response
    | InvalidArgumentProblemDetails
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | ValidationProblemDetails
    | ProblemDetails;
}
