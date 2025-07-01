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

## OpenAPI Specification

This API is documented in **OpenAPI format version 3** you can use tools like the [OpenAPI Generator](https://github.com/OpenAPITools/openapi-generator) to generate API clients for for example the languages we don't provide a pre-built client for. This is documented [here](/api/v1/articles/clients/generation).

## Changelog

View changelog [here](CHANGELOG.md)