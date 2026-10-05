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
  @doc("Geeft een waardering terug op basis van de ID. Het waarderingsobject zal gefilterd terugkomen, afhankelijk van het client_id dat gebruikt is voor de authenticatie.")
  @useAuth(oauth<["api:waarderingen:read"]>)
  @route("/{id}")
  @get
  @summary("Haal een waardering op.")
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
    | ExpiredValuationProblemDetails
    | NotFoundProblemDetails
    | ValidationProblemDetails
    | ProblemDetails;

  /**
  * Het waarderingsobject zal gefilterd terugkomen, afhankelijk van het client_id dat gebruikt is voor de authenticatie.
   *
   * Op dit moment kan alleen de waarderingsstatus gepatcht worden.
   * Dit endpoint kan gebruikt worden om een waarderingsinitialisatie te bevestigen.
   *
   * ### Callbacks
   * | Name | Url | Schema |
   * | --- | --- | --- |
   * | waardering | {configuredWebhookUrl}waardering | [WaarderingWebhookPayload](#models/WaarderingWebhookPayload) |
   * | deel-waardering | {configuredWebhookUrl}deel-waardering | [DeelWaarderingWebhookPayload](#models/DeelWaarderingWebhookPayload) |
   *
   */
  @useAuth(oauth<["api:waarderingen:patch"]>)
  @route("/{id}")
  @patch(#{ implicitOptionality: false })
  @summary("Werk een waardering bij.")
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

  @doc("Geeft de ontwikkeling van een waardering terug. Het waarderingsobject zal gefilterd terugkomen, afhankelijk van het client_id dat gebruikt is voor de authenticatie.")
  @useAuth(oauth<["api:waarderingen:ontwikkeling"]>)
  @route("/{id}/ontwikkeling")
  @get
  @summary("Haal waarderingsontwikkeling op.")
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
    Het waarderingsobject zal gefilterd terugkomen, afhankelijk van het client_id dat gebruikt is voor de authenticatie.
    Alle items kunnen gebruikt worden voor het zoeken, ProductType en BagNummeraanduidingId zijn verplicht.  
    """)
  @useAuth(oauth<["api:waarderingen:read"]>)
  @route("/zoeken")
  @post
  @summary("Zoek waarderingen.")
  @operationId("SearchWaarderingen")
  op SearchWaarderingen(@bodyRoot body: WaarderingZoekParameters):
    | SearchWaarderingen200Response
    | InvalidArgumentProblemDetails
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | ValidationProblemDetails
    | ProblemDetails;

  /**
  * Het waarderingsobject zal gefilterd terugkomen, afhankelijk van het client_id dat gebruikt is voor de authenticatie.
   * Nadat de waardering aangemaakt is zal deze bevestigd moeten worden. De BagNummeraanduidingId en ProductType velden zijn (ten minste) verplicht.
   *
   * ### Callbacks
   * | Name | Url | Schema |
   * | --- | --- | --- |
   * | waardering | {configuredWebhookUrl}waardering | [WaarderingWebhookPayload](#models/WaarderingWebhookPayload) |
   * | deel-waardering | {configuredWebhookUrl}deel-waardering | [DeelWaarderingWebhookPayload](#models/DeelWaarderingWebhookPayload) |
   *
   */
  @useAuth(oauth<["api:waarderingen:create"]>)
  @route("")
  @post
  @summary("Maak een waardering.")
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
  @summary("Controleer mogelijke producten.")
  @operationId("CheckProducten")
  op CheckProducten(@bodyRoot body: ProductCheckParameters):
    | CheckProducten200Response
    | InvalidArgumentProblemDetails
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | ValidationProblemDetails
    | ProblemDetails;

  /**
   * Zoekt een waardering op basis van de upper-case hexadecimal SHA-256-hash van een PDF-rapport.
   * Bij een hashcollision wordt de nieuwste waardering teruggegeven.
   */
  @useAuth(oauth<["api:rapporten:read"]>)
  @route("/by-hash/{hash}")
  @get
  @summary("Zoek op rapport-hash.")
  @operationId("GetWaarderingByReportHash")
  op GetWaarderingByReportHash(
    /**
     * De SHA-256 hash van het bestand, in upper-case hex.
     */
    @format("hex")
    @pattern("^[A-F0-9]{64}$")
    @example("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855")
    @path
    hash: string,
  ):
    | GetWaardering200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | ExpiredValuationProblemDetails
    | NotFoundProblemDetails
    | ValidationProblemDetails
    | ProblemDetails;
}
