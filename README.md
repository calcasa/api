# Calcasa Public API

The Calcasa API is used to connect to Calcasa provided services.

## Client packages

<a href="https://www.nuget.org/packages/Calcasa.Api/">
<img alt="Nuget package" src="https://img.shields.io/nuget/v/Calcasa.Api?label=Nuget"/>
</a>
<a href="https://packagist.org/packages/calcasa/api">
<img alt="Packagist package" src="https://img.shields.io/packagist/v/calcasa/api?label=Packagist"/>
</a>
<a href="https://pypi.org/project/calcasa-api/">
<img alt="PyPi package" src="https://img.shields.io/pypi/v/calcasa-api?label=PyPi"/>
</a>

## Client implementation notes

Clients should at all times be tolerant to the following:

- Extra fields in responses
- Empty or hidden fields in responses
- Extra values in enumerations
- Unexpected error responses in the form of [Problem Details](https://rfc-editor.org/rfc/rfc7807)

## TypeSpec Specification

This API is documented in [TypeSpec](https://typespec.io/), we generate an [OpenAPI format version 3](https://spec.openapis.org/oas/v3.0.0.html) specification from this, you can use tools like the [OpenAPI Generator](https://github.com/OpenAPITools/openapi-generator) to generate API clients for for example the languages we don't provide a pre-built client for. This is documented [here](/api/v1/articles/clients/generation).

## Changelog

View changelog [here](CHANGELOG.md)

## Cross-Origin Resource Sharing

This API features Cross-Origin Resource Sharing (CORS) implemented in compliance with [W3C spec](https://www.w3.org/TR/cors/).
And that allows cross-domain communication from the browser.
All responses have a wildcard same-origin which makes them completely public and accessible to everyone, including any code on any site.

## Authentication

Authentication is done via [OAuth2](https://oauth.net/2/) and the [client credentials](https://oauth.net/2/grant-types/client-credentials/) or [authorization code](https://oauth.net/2/grant-types/authorization-code/) grant types.