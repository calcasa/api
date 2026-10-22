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
  `x-scalar-sdk-installation`: #[
    #{
      lang: "C#",
      description: """
        Install [Calcasa.Api](https://www.nuget.org/packages/Calcasa.Api/) from NuGet in your .NET project. The generated SDK targets .NET 8, 9 and 10.

        ```sh
        dotnet add package Calcasa.Api
        ```

        To use a preview SDK, add `--prerelease`. Choose a package version that matches the API version you use.

        The SDK uses the .NET Generic Host and dependency injection. Register the client with `ConfigureApi`, configure its base address with `AddApiHttpClients`, and resolve API interfaces such as `Calcasa.Api.Api.IAdressenApi` from the service provider.

        Use `https://api.staging.calcasa.nl/api/v1` for staging or `https://api.calcasa.nl/api/v1` for production. Obtain OAuth2 credentials from Calcasa for the chosen environment. For a server-to-server integration, request an access token using the client credentials grant and register it as an `OAuthToken` with `options.AddTokens`. Keep credentials on the server and renew tokens before they expire; installing the SDK does not configure token acquisition or renewal.

        See the [C# examples](https://github.com/calcasa/api/tree/main/examples/csharp) and [example setup instructions](https://github.com/calcasa/api/blob/main/examples/README.md) for token acquisition, client registration and API calls. The examples require .NET 10.
        """
    },
    #{
      lang: "PHP",
      description: """
        Install [calcasa/api](https://packagist.org/packages/calcasa/api) using Composer. Requires PHP 8.1 or later.

        ```sh
        composer require calcasa/api
        ```

        Load `vendor/autoload.php` in your application. Create a `Calcasa\\Api\\Configuration`, set the base URL with `setHost(...)` and the OAuth2 access token with `setAccessToken(...)`, then pass the configuration to an API class such as `Calcasa\\Api\\Api\\AdressenApi`.

        Use `https://api.staging.calcasa.nl/api/v1` for staging or `https://api.calcasa.nl/api/v1` for production. Obtain OAuth2 credentials from Calcasa for the chosen environment. For a server-to-server integration, request an access token using the client credentials grant. Keep credentials on the server and renew tokens before they expire; installing the SDK does not configure token acquisition or renewal.

        See the [PHP examples](https://github.com/calcasa/api/tree/main/examples/php) and [example setup instructions](https://github.com/calcasa/api/blob/main/examples/README.md) for token acquisition and API calls. The repository examples use a local Composer path repository; use the Composer command above when integrating the published package into your own application.
        """
    },
    #{
      lang: "Python",
      description: """
        Install [calcasa-api](https://pypi.org/project/calcasa-api/) with pip, preferably in a virtual environment. Requires Python 3.10 or later.

        ```sh
        python -m venv .venv
        ```

        Activate it with `.venv\\Scripts\\Activate.ps1` on Windows PowerShell or `source .venv/bin/activate` on macOS/Linux, then install the SDK:

        ```sh
        python -m pip install calcasa-api
        ```

        To use a preview SDK, add `--pre`. The distribution name is `calcasa-api`, but the Python import is `calcasa.api`.

        Create a `calcasa.api.Configuration(host=...)` and set its `access_token` to an OAuth2 access token. Use `with calcasa.api.ApiClient(configuration) as api_client:` and pass that client to an API class such as `calcasa.api.AdressenApi`.

        Use `https://api.staging.calcasa.nl/api/v1` for staging or `https://api.calcasa.nl/api/v1` for production. Obtain OAuth2 credentials from Calcasa for the chosen environment. For a server-to-server integration, request an access token using the client credentials grant. Keep credentials on the server and renew tokens before they expire; installing the SDK does not configure token acquisition or renewal.

        See the [Python examples](https://github.com/calcasa/api/tree/main/examples/python) and [example setup instructions](https://github.com/calcasa/api/blob/main/examples/README.md) for token acquisition and API calls.
        """
    }
  ]
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
