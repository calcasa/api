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
  op GetCallbacks():
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

  /**
   * Het callback authentication object zal gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.
   */
  @useAuth(oauth<["api:configuratie:read"]>)
  @route("/callbacks/authentication")
  @get
  @summary("Haal de geconfigureerde callback authenticatie op voor de huidige client.")
  @operationId("GetCallbackAuthentication")
  op GetCallbackAuthentication():
    | GetCallbackAuthentication200Response
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | ProblemDetails;

  /**
   * Update callback authentication object zal gefilterd terug komen afhankelijk van het client_id wat gebruikt is voor de authenticatie.
   */
  @useAuth(oauth<["api:configuratie:write"]>)
  @route("/callbacks/authentication")
  @post
  @summary("Update de geconfigureerde callback authenticatie voor de huidige client.")
  @operationId("PostCallbackAuthentication")
  op PostCallbackAuthentication(@bodyRoot body: CallbackAuthentication):
    | PostCallbackAuthentication200Response
    | InvalidArgumentProblemDetails
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | ProblemDetails;

  /**
   * Get the JWKS keys, deze kunnen worden gebruikt om de echtheid van webhooks te verifiëren
   */
  @useAuth(oauth<["api:configuratie:read"]>)
  @route("/callbacks/signature-keys")
  @get
  @summary("Get the JWKS keys, deze kunnen worden gebruikt om de echtheid van webhooks te verifiëren.")
  @operationId("GetSignatureKeys")
  op GetSignatureKeys():
    | File<"application/jwk-set+json", Contents = bytes>
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | ProblemDetails;

  /**
   * Get the self-signed mTLS certificate.
   */
  @useAuth(oauth<["api:configuratie:read"]>)
  @route("/callbacks/mtls-certificate")
  @get
  @summary("Get the self-signed mTLS certificate.")
  @operationId("GetMtlsCertificate")
  op GetMtlsCertificate():
    | File<"application/x-x509-user-cert", Contents = bytes>
    | UnauthorizedProblemDetails
    | PermissionsDeniedProblemDetails
    | ProblemDetails;

  // /**
  //  * Haal een CSR op voor mTLS ondertekening.
  //  */
  // @useAuth(oauth<["api:configuratie:write"]>)
  // @route("/callbacks/mtls-csr")
  // @post
  // @summary("Haal een CSR op voor mTLS ondertekening.")
  // @operationId("GenerateMtlsCsr")
  // op GenerateMtlsCsr(@bodyRoot body: MTLSCSRRequest):
  //   | File<"application/pkcs10", Contents = bytes>
  //   | InvalidArgumentProblemDetails
  //   | UnauthorizedProblemDetails
  //   | PermissionsDeniedProblemDetails
  //   | ProblemDetails;

  // /**
  //  * Post een certificaat op voor mTLS ondertekening.
  //  */
  // @useAuth(oauth<["api:configuratie:write"]>)
  // @route("/callbacks/mtls-cert")
  // @post
  // @summary("Post een certificaat voor mTLS ondertekening.")
  // @operationId("PostMtlsCert")
  // op PostMtlsCert(
  //   @body file: File<"application/x-x509-user-cert", Contents = bytes>,
  // ):
  //   | GetMtlsCert200Response
  //   | InvalidArgumentProblemDetails
  //   | UnauthorizedProblemDetails
  //   | PermissionsDeniedProblemDetails
  //   | ProblemDetails;
}
