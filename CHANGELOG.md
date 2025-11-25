# Changelog


## 2025-11-25 (v1.4.0)

- Change API to TypeSpec as source of truth.
- Change generated libraries to `openapi-generator` version 7 with modified templates (see `templates` directory).
    - PHP
        - Minimal changes in the use of the library.
    - Python
        - Imports have changes, all models and apis are in separate modules and some have moved for example `api.model` -> `api.models` and `api.apis` -> `api.api`.
        - Model members are now `snake_case`.
        - Enums are now derived from `enum.Enum`.
        - `JsonPatchDocument` has been replaced with `list[Operation]`.
        - Files are now returned as plain `bytearray`.
    - C#
        - New library is generic host based, so `Configuration` class has been removed and more. See the new example on how to use the client with tokens.
        - Uses `System.Text.Json` for JSON processing
        - `JsonPatchDocument`, `Operation` and `OperationType` were dropped and now use the models from `Microsoft.AspNetCore.JsonPatch`
        - `ValidationProblemDetails` and `ProblemDetails` were dropped and now use the models from `Microsoft.AspNetCore.Mvc.Core`
        - Sync versions of operations been removed, added Events based alternative
- Add `taxatieorganisatieWeergave` to `Taxatiedata` model.
- Added `geenEigenBewoning` and `incorrecteErfpacht` values to `BusinessRulesCode`.

## 2025-11-12 (v1.4.0-rc4)

- Disabled `seal-object-schemas` TypeSpec emitter option.
- Added `geenEigenBewoning` and `incorrecteErfpacht` values to `BusinessRulesCode`.

## 2025-10-28 (v1.4.0-rc3)

- Add `taxatieorganisatieWeergave` to `Taxatiedata` model.

## 2025-10-02 (v1.4.0-rc2)

- Updated code formatting.
- Update client generation tooling and templates.

## 2025-07-01 (v1.4.0-rc1)

- Change API to TypeSpec as source of truth.
- Change generated libraries to `openapi-generator` version 7 with modified templates (see `templates` directory).
    - PHP
        - Minimal changes in the use of the library.
    - Python
        - Imports have changes, all models and apis are in separate modules and some have moved for example `api.model` -> `api.models` and `api.apis` -> `api.api`.
        - Model members are now `snake_case`.
        - Enums are now derived from `enum.Enum`.
        - `JsonPatchDocument` has been replaced with `list[Operation]`.
        - Files are now returned as plain `bytearray`.
    - C#
        - New library is generic host based, so `Configuration` class has been removed and more. See the new example on how to use the client with tokens.
        - Uses `System.Text.Json` for JSON processing
        - `JsonPatchDocument`, `Operation` and `OperationType` were dropped and now use the models from `Microsoft.AspNetCore.JsonPatch`
        - `ValidationProblemDetails` and `ProblemDetails` were dropped and now use the models from `Microsoft.AspNetCore.Mvc.Core`
        - Sync versions of operations been removed, added Events based alternative

## 2024-05-14 (v1.3.1)

- Add `DeelWaarderingWebhookPayload` model.
- Use of strings for CBS codes.
    - Add `buurtCode` field to `CbsIndeling` model.
    - Allow for string input for endpoint `buurt`.
- Add UserAgent header to callback requests with format: CalcasaPublicAPI/`<version>`

## 2023-11-14 (v1.3.0)

- Add `geldverstrekker` field to the `CallbackInschrijving` model.
- Add support for mTLS on the callback service.
    - By default when requested by the target server the public CA signed TLS certificate with the appropriate domain as Common Name will be offered as the client certificate.
    - Public TLS Certificates rotate every couple of months.
- Change a couple of `date-time` fields that only contained a date to pure `date` fields. This might result is a different type in the generated clients and the service-side validation will be more strict. Times included in values will no longer be silently dropped, but will generate an error.
    - Change `Modeldata` model `waardebepalingsdatum` field to type `date` in OpenAPI spec.
    - Change `Bestemmingsdata` model `datumBestemmingplan` field to type `date` in OpenAPI spec.
    - Change `Bodemdata` model `datumLaatsteOnderzoek` field to type `date` in OpenAPI spec.
    - Change `Referentieobject` model `verkoopdatum` field to type `date` in OpenAPI spec.
    - Change `VorigeVerkoop` model `verkoopdatum` field to type `date` in OpenAPI spec.
    - Change `waarderingInputParameters` model `peildatum` field to type `date` in OpenAPI spec. This is an input field and will now require a date without a time.
- Add `desktopTaxatieHerwaardering` product to enumeration `ProductType`.
- The service no longer returns CORS headers.
- Actions now correctly report the 'application/problem+json' Content-Type in the documentation for the `HTTP 422 Unprocessable Entity` responses.
- Added `energielabelData` field to `Objectdata` model to contain the extra information about the energy label.
- The OpenAPI spec generation was changed slightly and thus the generated and published clients might be affected. There might be some slight breaking changes at compile time, but the functionality remains the same.
    - For example for C# and PHP `AdresInfoAdres` is now just covered by `Adres`
    - Likewise for the `Omgevingsdata*` models that are now all covered by `Gebiedsdata`
    - For a lot of the `Waardering*` models they are now using the correct model names, like `WaarderingModel` -> `Modeldata`

## 2023-04-17 (v1.2.1)

- Add `externeReferentie` field to the `CallbackInschrijving` and `WaarderingWebhookPayload` models.

## 2022-08-04 (v1.2.0)

- Add support for managing `CallbackSubscription`'s, this allows you to subscribe to callbacks for valuations that were not created with your API client.
    - `GET /v1/callbacks/inschrijvingen`
    - `POST /v1/callbacks/inschrijvingen`
    - `GET /v1/callbacks/inschrijvingen/{bagNummeraanduidingId}`
    - `DELETE /v1/callbacks/inschrijvingen/{bagNummeraanduidingId}`
- Add `taxateurnaam` field to the `Taxatiedata` model.
- Callback URIs should now end in `/` not just contain it to help stop common errors (ending in `=` is also still allowed when using a query string).
- Updating configuration in the `POST /v1/configuratie/callbacks` endpoint now clears stored but decommissioned versions from the configuration object.
- Add `klantkenmerk` to the `WaarderingInputParameters` and `Waardering` models.

## 2022-07-12 (v1.1.7)

- Added support for the OAuth 2.0 authorization code flow for use of the API with user accounts.
- Add `bouweenheid` to `FunderingSoortBron` enumeration.

## 2022-05-19 (v1.1.6)

- Added `ltvTeHoogOverbrugging` value to the `BusinessRulesCode` enumeration.

## 2022-04-13 (v1.1.5)

- Fix the schema for `Operation` `value` field for the benefit of the PHP and Python code generators, these will now correctly support any value type.

## 2022-04-12 (v1.1.4)

- Added proper Content-Disposition headers to the `GET /v1/rapporten/{id}` and `GET /v1/facturen/{id}` endpoints with the correct filename.
- Fix Mime Types for the `POST /v1/configuratie/callbacks` endpoint to only accept `application/json`.
- Fix C# API client to correctly use the `application/json-patch+json` content type in requests that require it.
- Fix C# client's `FileParameter` type correct handling of response headers like `Content-Disposition` and `Content-Type`.
- Removed C# client's useless implementation of `IValidatableObject`.
- Fix Python client's internal namespace name being illegal `calcasa-api` -> `calcasa.api`.

## 2022-03-22 (v1.1.3)

- Add 402 (Payment required) and 422 (Unprocessable entity) as potential response for `PATCH /v1/waarderingen/{id}`.

## 2022-03-17 (v1.1.2)

- Fixed response type for `GET /v1/geldverstrekkers/{productType}` endpoint.

## 2022-03-08 (v1.1.1)

- Added `GET /v1/geldverstrekkers/{productType}` endpoint.
- Restored all `ProblemDetails` models.

## 2022-03-07 (v1.1.0)

- Added `isErfpacht` to `WaarderingInputParameters`.
- Cleaned up serialization of null values, they should no longer appear in the output.

## 2021-02-04

- Added extra clarification to the documentation pertaining to the `WaarderingInputParameters` and which fields are required for the different input parameter combinations.

## 2022-01-11 (v1.0.2)

- Fixed `GET /api/v1/bodem/{id}` endpoint path parameter description, query parameter was never meant to be there.

## 2021-12-23

- Clarified the documentation pertaining to the `WaarderingInputParameters` and which fields are required for the different product types.

## 2021-12-22 (v1.0.1)

- Dates are now serialized in the ISO date-only format `yyyy-MM-dd` to stop any confusion around timezones and are all assumed to be in UTC.
    - `peildatum` in `WaarderingsInputParameters`
    - `datum_bestemmingplan` in `Bestemmingsdata`
    - `datum_laatste_onderzoek` in `Bodemdata`
    - `verkoopdatum` in `Referentieobject`
    - `verkoopdatum` in `VorigeVerkoop`
    - `waardebepalingsdatum` in `Modeldata`
- Reintroduced the `WaarderingWebhookPayload` model that was omitted.

## 2021-12-21

- Patching the status of a `Waardering` object will now immediately reflect its new status in the response object.

## 2021-12-13 (v1.0.0)

- Initial release of `v1` based on `v0.0.6`

# Previous versions changelogs

## 2022-02-02

- API version `v0` was removed from service.

## 2021-12-23

- Mark `v0` as officially deprecated. No further versions will be released. Every implementation should move to `v1`

## 2021-12-10 (v0.0.6)

- Added extra field `peildatum` to the `WaarderingInputParameters` model.

## 2021-11-25 (v0.0.5)

- Updated all reported OAuth2 scopes and reduced the superfluous scope information on each endpoint.

## 2021-11-23 (v0.0.4)

- Added per square meter developments to the `WaarderingOntwikkeling` object (fields with the `PerVierkantemeter` suffix).

## 2021-11-15 (v0.0.3)

- Added callback update and read endpoints and models.
- Updated documentation.

## 2021-11-11

- Renamed /fundering endpoint to /funderingen to be more in line with other endpoints
- Renamed `HerstelType` to `FunderingHerstelType`.
- Added `FunderingType` values.

## 2021-11-10

- Adjusted OpenAPI Spec generation to fix some issues with certain generators. This also means that the nullable nature of certain fields is now correctly represented. Please refer to the Generation article for more information, the config files were updated as well.

## 2021-11-09

- Added `Status` and `Taxatiedatum` to `Taxatiedata` model.

## 2021-11-08

- Renamed `id` field in `AdresInfo` model to `bagNummeraanduidingId`.
- Added `GET /v0/fundering/{id}` endpoint with corresponding models.
- Changed HTTP response code for the `BusinessRulesProblemDetails` error return type of `POST /v0/waardering` from `422 Unprocessable Entity` to `406 Not Acceptable` to fix a duplicate.

## 2021-10-13

- Added `taxatie` field to `Waardering` model.
- Added `Taxatiedata` model containing the `taxatieorganisatie` field for desktop valuations.

## 2021-09-29

- Added `aangemaakt` timestamp field to `Waardering` model.
- Added `WaarderingZoekParameters` model to replace `WaarderingInputParameters` in the `POST /v0/waarderingen/zoeken` endpoint.
- Split `Omgevingsdata` model into a set of separate `Gebiedsdata` models that also contain extra statistics.
- Added `bijzonderheden` field to `VorigeVerkoop` model.
- Renamed `ReferentieBijzonderheden` model to `VerkoopBijzonderheden`.

## 2021-09-22

- Initial release of `v0`
