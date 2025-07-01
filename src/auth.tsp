import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";
import "@typespec/versioning";

using Http;
using OpenAPI;


// model oidc<Scopes extends string[]>
//   is OpenIdConnectAuth<
//     "https://authentication.calcasa.nl/oauth2/v2.0/.well-known/openid-configuration",
//     Scopes
//   >;

model oauth<Scopes extends string[]>
  is OAuth2Auth<
    [
      // Uncomment when https://github.com/microsoft/typespec/issues/7685 is fixed
      // {
      //   type: OAuth2FlowType.authorizationCode;
      //   authorizationUrl: "https://authentication.calcasa.nl/oauth2/v2.0/authorize";
      //   tokenUrl: "https://authentication.calcasa.nl/oauth2/v2.0/token";
      //   refreshUrl: "https://authentication.calcasa.nl/oauth2/v2.0/token";
      // },
      {
        type: OAuth2FlowType.clientCredentials;
        tokenUrl: "https://authentication.calcasa.nl/oauth2/v2.0/token";
      }
    ],
    Scopes
  >;
