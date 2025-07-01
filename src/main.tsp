import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";
import "@typespec/versioning";

import "./auth.tsp";
import "./errors.tsp";
import "./enums.tsp";
import "./versions.tsp";
import "./models.tsp";
import "./operations.tsp";

using TypeSpec.Versioning;
using Http;
using OpenAPI;

/**
 * The Calcasa API is used to connect to Calcasa provided services.
 * For more information, please visit [Documentation](https://docs.calcasa.nl) or [GitHub](https://github.com/calcasa/api).
 */
@service(#{ title: "Calcasa Public API"})
@info(#{
  contact: #{ url: "https://www.calcasa.nl/contact", email: "info@calcasa.nl" },
  license: #{
    name: "Apache License 2.0",
    url: "https://spdx.org/licenses/Apache-2.0.html",
  },
  termsOfService: "https://calcasa.nl/gebruiksvoorwaarden",
})
@useAuth(oauth<[]>)
@server("https://api.staging.calcasa.nl/api/{apiVersion}", "Staging", 
  {
    @path
    apiVersion : VersionNames = VersionNames.v1,
  }) // Staging server (used for development and testing)
@server("https://api.calcasa.nl/api/{apiVersion}", "Production", 
  {
    @path apiVersion : VersionNames = VersionNames.v1,
  }) // Default server last
@versioned(Versions)
namespace CalcasaPublicApi;
