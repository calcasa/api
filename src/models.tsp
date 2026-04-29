import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";
import "@typespec/versioning";

import "./errors.tsp";
import "./enums.tsp";

using TypeSpec.Versioning;
using Http;
using OpenAPI;

namespace CalcasaPublicApi;

model Adres {
  /**
   * De straatnaam zoals geschreven in de BAG (Basisregistratie Adressen en Gebouwen).
   */
  @example("Voorbeeldstraat")
  straat?: string;

  /**
   * Het huisnummer.
   */
  @example(123)
  huisnummer?: int32;

  /**
   * De huisnummertoevoeging.
   */
  @example("A")
  huisnummertoevoeging?: string | null;

  /**
   * De postcode met 4 cijfers en 2 letters zonder spatie.
   */
  @example("1234AB")
  @pattern("^[0-9]{4}[A-Z]{2}$")
  postcode?: string;

  /**
   * De woonplaats zoals geschreven in de BAG (Basisregistratie Adressen en Gebouwen).
   */
  @example("Voorbeeldstad")
  woonplaats?: string;
}

model AdresInfo {
  /**
   * Het BAG nummeraanduiding Id van het adres.
   * Normaal aangevuld met nullen tot 16 karakters.
   */
  @key bagNummeraanduidingId: int64;

  adres?: Adres;
  notities?: Notities;

  /**
   * Geeft aan of er een correct adres is gevonden voor deze zoekopdracht.
   */
  adresGevonden?: boolean | null;
}

model Bestemmingsdata {
  /**
   * De enkelbestemming volgens het bestemmingsplan.
   */
  @example("woongebied")
  enkelbestemming?: string | null;

  /**
   * De datum waarop dit bestemmingsplan vastgelegd is.
   */
  @example(plainDate.fromISO("2021-04-28"))
  datumBestemmingplan?: plainDate | null;
}

model Bodemdata {
  status?: BodemStatusType;

  /**
   * De datum van het laatste bodemonderzoek.
   */
  @example(plainDate.fromISO("2021-04-28"))
  datumLaatsteOnderzoek?: plainDate | null;

  /**
   * De url met informatie over het bodemonderzoek.
   */
  url?: url | null;
}

model Callback {
  /**
   * De API versie waarvoor deze callback aangeroepen wordt.
   */
  version?: string;

  /**
   * De URL van de callback. Bij het aanroepen zal de CallbackName hier achter geplaatst worden. Null of lege string om te verwijderen. English: when making the call, the CallbackName will be appended to this Url. Null or empty string to remove.
   */
  @maxLength(2048) url?: string | null;
}

model CallbackAuthentication {
  /**
   * Het type mTLS authenticatie dat gebruikt wordt voor de callback.
   */
  mTlsType: MTLSType;

  /**
   * De Authorization header scheme die gebruikt moet worden bij het aanroepen van de callback URL. 
   * Maximale lengte van 128 tekens. Voorbeelden zijn "Basic" of "Bearer". 
   * Als deze leeg is wordt de header achterwege gelaten. Dit veld is verplicht als `authorizationHeaderValue` is ingevuld. 
   * 
   * Zie ook: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Authorization
   */
  @maxLength(128)
  authorizationHeaderScheme?: string | null;

  /**
   * De Authorization header value die gebruikt moet worden bij het aanroepen van de callback URL. 
   * Deze wordt plain text accessible opgeslagen, dus gebruik unieke credentials voor deze service. De maximale lengte van de header is 2048 tekens. 
   * Als deze leeg is wordt de header achterwege gelaten. Dit veld is verplicht als `authorizationHeaderScheme` is ingevuld.  Dit is een write-only veld.
   * 
   * Zie ook: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Authorization
   */
  @maxLength(2048)
  authorizationHeaderValue?: string | null;
}

model CallbackInschrijving {
  /**
   * Verplicht.
   * Het BAG (Basisregistratie Adressen en Gebouwen) nummeraanduiding id.
   */
  bagNummeraanduidingId: int64;

  /**
   * Verplicht.
   * De datum tot wanneer deze inschrijving effect moet hebben. Als deze inschrijving verloopt wordt deze automatisch opgeruimt. De maximale termijn is afhankelijk van de gebruikte client.
   */
  @example(utcDateTime.fromISO("2021-04-28T12:34:45Z"))
  @encode(DateTimeKnownEncoding.rfc3339)
  geldigTot: utcDateTime;

  /**
   * Een vrij veld dat terug komt met de callback payload om callbacks aan de juiste callback inschrijving te koppelen.
   */
  externeReferentie?: string | null;

  /**
   * Optioneel veld om alleen op aanvragen voor een bepaalde geldverstrekker in te schrijven.
   */
  geldverstrekker?: string | null;
}

model CbsIndeling {
  /**
   * De buurt code zoals bekend bij het CBS (Centraal Bureau voor de Statistiek).
   */
  buurtId?: int32;

  /**
   * De buurt code zoals bekend bij het CBS (Centraal Bureau voor de Statistiek).
   */
  buurtCode?: string;

  /**
   * De naam van de buurt.
   */
  buurtnaam?: string;

  /**
   * De naam van de wijk.
   */
  wijknaam?: string;

  /**
   * De naam van de gemeente.
   */
  gemeentenaam?: string;
}

model EnergielabelData {
  /**
   * Het aantal sterren van het energielabel. 1 is voorlopig label. 3 is beperkt definitief label (zonder energieprestatie-index). 4 is definitief label met energieprestatie-index.
   */
  aantalSterren?: int32 | null;

  /**
   * De registratiedatum. Beschikbaar voor 2 en 3 sterrenlabels.
   */
  geldigTot?: plainDate | null;

  /**
   * De datum tot wanneer het label geldig is. Beschikbaar voor 2 en 3 sterrenlabels.
   */
  registratiedatum?: plainDate | null;
}

model Factuur {
  /**
   * Het factuur Id.
   */
  @format("uuid") id: string;

  /**
   * Het factuurnummer van de factuur.
   */
  factuurnummer: string;
}

model Foto {
  /**
   * Het foto Id.
   */
  @format("uuid") id?: string;
}

/**
 * Informatie over een bepaald funderingrisico.
 */
model FunderingRisico {
  label?: FunderingRisicoLabel;
  bron?: FunderingSoortBron;

  /**
   * De omschrijving van het risico.
   */
  omschrijving?: string;
}

/**
 * Informatie over type fundering.
 */
model FunderingTypering {
  type?: FunderingType;
  bron?: FunderingSoortBron;

  /**
   * De omschrijving van het funderingstype.
   */
  omschrijving?: string;
}

/**
 * Uitvoer met funderingsinformatie.
 */
model Funderingdata {
  typering?: FunderingTypering;
  herstelType?: FunderingHerstelType;
  droogstandRisico?: FunderingRisico;
  optrekkendVochtRisico?: FunderingRisico;
  bioInfectieRisico?: FunderingRisico;

  /**
   * Indicatieve herstelkosten van de fundering.
   */
  herstelkosten?: float64 | null;

  bron?: FunderingDataBron;
}

model Gebiedsdata {
  naam?: string;

  /**
   * In hele euros.
   */
  @minValue(0)
  gemiddeldePrijsEengezinswoningen?: int32 | null;

  /**
   * In hele euros.
   */
  @minValue(0)
  gemiddeldePrijsMeergezinswoningen?: int32 | null;

  /**
   * In hele euros per vierkante meter.
   */
  @minValue(0)
  gemiddeldeVierkantemeterPrijsEengezinswoningen?: int32 | null;

  /**
   * In hele euros per vierkante meter.
   */
  @minValue(0)
  gemiddeldeVierkantemeterPrijsMeergezinswoningen?: int32 | null;

  /**
   * In hele procenten.
   */
  prijsveranderingAfgelopenJaar?: int32 | null;

  /**
   * In hele procenten.
   */
  prijsveranderingAfgelopen3Jaar?: int32 | null;

  /**
   * In hele procenten.
   */
  prijsveranderingAfgelopen5Jaar?: int32 | null;

  /**
   * In hele procenten.
   */
  prijsveranderingAfgelopen10Jaar?: int32 | null;
}

model Geldverstrekker {
  /**
   * De slug voor deze geldverstrekker, dit is de waarde die gebruikt moet worden als input voor andere endpoints.
   */
  slug?: string;

  /**
   * De volledige naam van deze geldverstrekker.
   */
  name?: string;
}

/**
 * Array of operations to perform
 */
model JsonPatchDocument is Operation[];

model Kwartaal {
  jaar?: int32;

  /**
   * Het kwartaal van 1 tot 4.
   */
  number?: int32;
}

model Modeldata {
  /**
   * In hele euros.
   */
  marktwaarde?: int32;

  /**
   * In hele euros.
   */
  marktwaardeOndergrens?: int32;

  /**
   * In hele euros.
   */
  marktwaardeBovengrens?: int32;

  /**
   * Op een schaal van 0 tot 7.
   */
  confidenceLevel?: float32;

  @example(plainDate.fromISO("2021-04-28"))
  waardebepalingsdatum?: plainDate;

  /**
   * In hele euros.
   */
  executiewaarde?: int32;
}

model Notities {
  straat?: Notitie;
  huisnummer?: Notitie;
  huisnummertoevoeging?: Notitie;
  postcode?: Notitie;
  woonplaats?: Notitie;
}

model Objectdata {
  woningType?: WoningType;
  bouwjaar?: int32;

  /**
   * Het woonoppervlak in hele vierkante meters.
   */
  oppervlak?: int32;

  /**
   * Het perceeloppervlak in hele vierkante meters.
   */
  perceeloppervlak?: int32;

  /**
   * De inhoud in hele kubieke meters.
   */
  inhoud?: int32;

  energielabel?: Energielabel;
  energielabelData?: EnergielabelData;
  bagPandId?: int64;
  bagVerblijfsobjectId?: int64;
}

model Opnamedata {
  /**
   * De algemene staat van onderhoud buiten.
   */
  algemeenOnderhoudBuiten?: OnderhoudStaat;
}

model Omgevingsdata {
  buurt?: Gebiedsdata;
  wijk?: Gebiedsdata;
  gemeente?: Gebiedsdata;
  provincie?: Gebiedsdata;
  land?: Gebiedsdata;
}

model Operation {
  `op`?: OperationType;

  @example("/a/b/c")
  from?: string | null;

  @example(#{ a: "b" })
  value?: unknown | null;

  @example("/d/e/f")
  path?: string;
}

model Rapport {
  /**
   * Het rapport Id.
   */
  @format("uuid") id: string;
}

model Referentieobject {
  /**
   * Afstand tot het waarderingsobject in meters.
   */
  afstand?: int32;

  /**
   * In hele euros.
   */
  verkoopprijs?: int32;

  /**
   * In hele euros.
   */
  gecorrigeerdeVerkoopprijs?: int32;

  /**
   * In hele euros.
   */
  geindexeerdeVerkoopprijs?: int32;

  /**
   * In hele euros per vierkante meters.
   */
  vierkantemeterprijs?: int32;

  /**
   * In hele euros per vierkante meters.
   */
  gecorrigeerdeVierkantemeterprijs?: int32;

  /**
   * In hele euros per vierkante meters.
   */
  geindexeerdeVierkantemeterprijs?: int32;

  /**
   * In UTC.
   */
  @example(plainDate.fromISO("2021-04-28"))
  verkoopdatum?: plainDate;

  adres?: Adres;
  object?: Objectdata;
  cbsIndeling?: CbsIndeling;

  /**
   * Fotos van het referentieobject.
   */
  fotos?: Foto[];

  /**
   * Eventuele bijzonderheden van de transactie.
   */
  bijzonderheden?: VerkoopBijzonderheden[];
}

model Taxatiedata {
  /**
   * De interne naam van de taxatieorganisatie. Deze wijzigt niet.
   */
  taxatieorganisatie?: string;

  /**
   * De externe of rapport naam van de taxatieorganisatie.
   */
  taxatieorganisatieWeergave?: string;

  /**
   * De naam van de taxateur die de waardering heeft behandeld.
   */
  taxateurnaam?: string;

  status?: Taxatiestatus;

  /**
   * De datum/tijd waarop de waardering getaxeerd is, in UTC.
   */
  @example(utcDateTime.fromISO("2021-04-28T12:34:45Z"))
  @encode(DateTimeKnownEncoding.rfc3339)
  taxatiedatum?: utcDateTime;
}

model VorigeVerkoop {
  /**
   * In hele euros.
   */
  verkoopprijs?: int32;

  /**
   * In hele euros.
   */
  geindexeerdeVerkoopprijs?: int32;

  /**
   * In hele euros per vierkante meter.
   */
  vierkantemeterprijs?: int32;

  /**
   * In hele euros per vierkante meter.
   */
  geindexeerdeVierkantemeterprijs?: int32;

  /**
   * In UTC.
   */
  @example(plainDate.fromISO("2021-04-28"))
  verkoopdatum?: plainDate;

  /**
   * Het perceeloppervlak in hele vierkante meters.
   */
  perceeloppervlak?: int32;

  /**
   * Eventuele bijzonderheden van de transactie.
   */
  bijzonderheden?: VerkoopBijzonderheden[];
}

model Waardering {
  @key @format("uuid") id: string;

  @doc("Het tijdsstempel van wanneer de waardering aangemaakt is.")
  @example(utcDateTime.fromISO("2021-04-28T12:34:45Z"))
  @encode(DateTimeKnownEncoding.rfc3339)
  aangemaakt: utcDateTime;

  status: WaarderingStatus;
  origineleInput: WaarderingInputParameters;
  adres: Adres;
  `model`?: Modeldata;
  taxatie?: Taxatiedata;
  object?: Objectdata;
  opname?: Opnamedata;
  cbsIndeling?: CbsIndeling;
  fotos?: Foto[] | null;
  referenties?: Referentieobject[] | null;
  vorigeVerkopen?: VorigeVerkoop[] | null;
  rapport?: Rapport;
  factuur?: Factuur;
}

model ProductCheckParameters {
  /**
   * Ongebruikt voor de meeste client typen op dit moment. Deze informatie komt uit de credentials. Als dit veld wel verplicht is dan is dit gecommuniceerd.
   */
  geldverstrekker?: string;

  /**
   * Verplicht voor de producttypen `modelwaardeDesktopTaxatie` en `desktopTaxatie`.
   * Voor het aanvraagdoel `hypotheekOphogen` is dit de som van de huidige hypotheeksom en de ophoging.
   * In hele euros.
   */
  hypotheekwaarde?: int32;

  aanvraagdoel?: Aanvraagdoel = Aanvraagdoel.onbekend;

  /**
   * Verplicht voor de producttypen `modelwaardeDesktopTaxatie` en `desktopTaxatie`.
   * In hele euros. De waarde zoals bekend bij de klant met bijbehorende KlantwaardeType.
   */
  klantwaarde?: int32;

  klantwaardeType?: KlantwaardeType = KlantwaardeType.onbekend;

  /**
   * Verplicht voor de producttypen `modelwaardeDesktopTaxatie` en `desktopTaxatie`.
   * Geeft aan of het te waarderen object een bestaande koopwoning is.
   */
  isBestaandeWoning?: boolean;

  /**
   * Verplicht voor alle producttypen.
   * Het BAG (Basisregistratie Adressen en Gebouwen) nummeraanduiding id.
   */
  bagNummeraanduidingId: int64;

  /**
   * Verplicht voor de producttypen `modelwaardeDesktopTaxatie` en `desktopTaxatie`.
   * Geeft aan of er gebruikt gemaakt wordt van de Nationale Hypotheekgarantie.
   */
  isNhg?: boolean;

  /**
   * Verplicht te gebruiken voor de combinatie van de producttypen `modelwaardeDesktopTaxatie` en `desktopTaxatie`, als er gebruikt gemaakt wordt van de Nationale Hypotheekgarantie (`isNhg`) en het aanvraagdoel niet `aankoopNieuweWoning` is.
   * Geeft aan of er bij de eventuele bestaande hypotheek gebruik is gemaakt van de Nationale Hypotheekgarantie.
   */
  isBestaandeNhgHypotheek?: boolean;

  /**
   * Verplicht voor de combinatie van de producttypen `modelwaardeDesktopTaxatie`, `desktopTaxatie` en `desktopTaxatiePlus` en het aanvraagdoel `overbruggingsfinanciering`.
   * In hele euros.
   */
  benodigdeOverbrugging?: int32;

  /**
   * Optioneel te gebruiken voor de producttypen `modelwaardeRisico`.
   * Peildatum voor de aanvraag. Standaard de datum van vandaag.
   * Supports yyyy-MM-dd or optionally yyyy-MM-ddTHH:mm:ssZ (ISO) with the time stamp assumed to be in UTC and the time is dropped before using the value.
   */
  @example(plainDate.fromISO("2021-04-28"))
  peildatum?: plainDate | null;

  /**
   * Potentieel verplicht voor de product typen `modelwaardeDesktopTaxatie`, `desktopTaxatie` en `desktopTaxatiePlus` afhankelijk van de geldverstrekker- en accountconfiguratie.
   */
  isErfpacht?: boolean | null;

  /**
   * Vrij veld voor het opslaan van een klantkenmerk, zoals bijvoorbeeld een dossiernummer of andere interne referentie. Dit veld komt later weer terug in het `origineleInput` veld in het `waardering` object.
   */
  @minLength(0) @maxLength(100) klantkenmerk?: string;

  /**
   * True als de lening een aflossingsvrij deel heeft. Potentieel verplicht voor de product typen `modelwaardeDesktopTaxatie`, `desktopTaxatie` en `desktopTaxatiePlus` afhankelijk van de geldverstrekker- en accountconfiguratie.
   */
  heeftAflossingsvrijDeel?: boolean | null;

  /**
   * De hoogte van het aflossingsvrije deel van het veld `hypotheekwaarde` van de lening. Alleen relevant als `heeftAflossingsvrijDeel` true is. Potentieel verplicht voor de product typen `modelwaardeDesktopTaxatie`, `desktopTaxatie` en `desktopTaxatiePlus` afhankelijk van de geldverstrekker- en accountconfiguratie.
   * In hele euros.
   */
  aflossingsvrijDeel?: int32 | null;
}

model ProductCheck {
  /**
   * De producttypen waarvoor met de gegeven input een waardering mogelijk is.
   */
  mogelijkeProducten: ProductCheckItem[];

  /**
   * De producttypen waarvoor met de gegeven input geen waardering mogelijk is.
   */
  afgekeurdeProducten: ProductCheckItem[];
}

model ProductCheckItem {
  /**
   * De producttypen waarvoor deze waardering geldt.
   */
  productType: ProductType;

  /**
   * Indien deze waardering niet voldoet aan de eisen voor dit product type, dan is dit veld ingevuld met de reden waarom deze is afgekeurd.
   */
  businessRulesCode?: BusinessRulesCode | null;
}

model WaarderingInputParameters {
  productType: ProductType;
  ...ProductCheckParameters;
}

model WaarderingOntwikkeling {
  /**
   * Id van de waardering.
   */
  @format("uuid") id?: string;

  /**
   * De prijsontwikkeling van het gewaardeerde object.
   */
  objectPrijsOntwikkeling?: WaarderingOntwikkelingKwartaal[];

  /**
   * De prijsontwikkeling van het gewaardeerde object per vierkantemeter.
   */
  objectPrijsOntwikkelingPerVierkantemeter?: WaarderingOntwikkelingKwartaal[];

  /**
   * De prijsontwikkeling van de buurt van het gewaardeerde object.
   */
  buurtPrijsOntwikkeling?: WaarderingOntwikkelingKwartaal[];

  /**
   * De prijsontwikkeling van de buurt van het gewaardeerde object per vierkantemeter.
   */
  buurtPrijsOntwikkelingPerVierkantemeter?: WaarderingOntwikkelingKwartaal[];

  /**
   * De prijsontwikkeling van de wijk van het gewaardeerde object.
   */
  wijkPrijsOntwikkeling?: WaarderingOntwikkelingKwartaal[];

  /**
   * De prijsontwikkeling van de wijk van het gewaardeerde object per vierkantemeter.
   */
  wijkPrijsOntwikkelingPerVierkantemeter?: WaarderingOntwikkelingKwartaal[];

  /**
   * De prijsontwikkeling van de gemeente van het gewaardeerde object.
   */
  gemeentePrijsOntwikkeling?: WaarderingOntwikkelingKwartaal[];

  /**
   * De prijsontwikkeling van de gemeente van het gewaardeerde object per vierkantemeter.
   */
  gemeentePrijsOntwikkelingPerVierkantemeter?: WaarderingOntwikkelingKwartaal[];
}

model WaarderingOntwikkelingKwartaal {
  kwartaal?: Kwartaal;

  /**
   * In hele euros.
   */
  waarde?: int32;
}

/**
 * De base payload van de webhooks die verstuurd worden voor verschillende events.
 */
model WebhookPayload {
  @visibility(Lifecycle.Read)
  callbackName: string;

  /**
   * Uniek Id voor deze callback.
   */
  @format("uuid") eventId: string;

  /**
   * Het tijdstip van het event, in UTC.
   */
  @example(utcDateTime.fromISO("2021-04-28T12:34:45Z"))
  @encode(DateTimeKnownEncoding.rfc3339)
  timestamp: utcDateTime;
}

/**
 * De payload van de webhooks voor de waarderingen.
 */
model WaarderingWebhookPayload {
  ...WebhookPayload;

  /**
   * Het Id van de waardering waarop deze callback betrekking heeft.
   */
  @format("uuid") waarderingId?: string;

  oldStatus?: WaarderingStatus;
  newStatus?: WaarderingStatus;

  /**
   * Geeft aan of de betreffende waardering aangevraagd is met een test token.
   */
  isTest?: boolean;

  /**
   * Dit is de externe referentie opgegeven bij de callback inschrijving of als dit een normale API waardering is waarvoor geen callback inschrijving was dit veld null.
   */
  externeReferentie?: string | null;
}

/**
 * De payload van de webhooks die verstuurd worden op het moment dat een klant toestemming geeft voor het delen van een waardering.
 */
model DeelWaarderingWebhookPayload {
  ...WebhookPayload;

  /**
   * Het Id van de waardering waarop deze callback betrekking heeft.
   */
  @format("uuid") waarderingId?: string;
}

model WaarderingZoekParameters {
  /**
   * De datum/tijd waarop de waardering is aangemaakt, in UTC.
   */
  @example(utcDateTime.fromISO("2021-04-28T12:34:45Z"))
  @encode(DateTimeKnownEncoding.rfc3339)
  aangemaakt?: utcDateTime | null;

  /**
   * De naam van de geldverstrekker voor de waardering.
   */
  geldverstrekker?: string | null;

  productType: ProductType;
  aanvraagdoel?: Aanvraagdoel | null;
  waarderingStatus?: WaarderingStatus | null;

  /**
   * Verplicht.
   */
  bagNummeraanduidingId: int64;
}

/**
 * OK
 */
model GetAdres200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: AdresInfo;
}

/**
 * OK
 */
model SearchAdres200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: AdresInfo;
}

/**
 * OK
 */
model GetBestemmingById200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: Bestemmingsdata;
}

/**
 * OK
 */
model GetBodemById200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: Bodemdata;
}

/**
 * OK
 */
model GetBuurt200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: Omgevingsdata;
}

/**
 * OK
 */
model GetNotificationSubscriptions200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: CallbackInschrijving[];
}

/**
 * OK
 */
model AddOrUpdateCallbackSubscription200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: CallbackInschrijving;
}

/**
 * No Content
 */
model DeleteNotificationSubscription204Response {
  @statusCode statusCode: 204;
}

/**
 * OK
 */
model GetNotificationSubscription200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: CallbackInschrijving;
}

/**
 * OK
 */
model GetCallbacks200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: Callback[];
}

/**
 * OK
 */
model GetCallbackAuthentication200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: CallbackAuthentication;
}

/**
 * OK
 */
model PostCallbackAuthentication200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: CallbackAuthentication;
}

/**
 * OK
 */
model UpdateCallbacks200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: Callback[];
}

/**
 * OK
 */
model GetFunderingById200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: Funderingdata;
}

/**
 * OK
 */
model GetGeldverstrekkers200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: Geldverstrekker[];
}

/**
 * OK
 */
model GetWaardering200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: Waardering;
}

/**
 * OK
 */
model PatchWaarderingen200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: Waardering;
}

/**
 * OK
 */
model GetWaarderingOntwikkeling200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: WaarderingOntwikkeling;
}

/**
 * OK
 */
model SearchWaarderingen200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: Waardering[];
}

/**
 * OK
 */
model CreateWaardering200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: Waardering;
}

/**
 * OK
 */
model CheckProducten200Response {
  @statusCode statusCode: 200;
  @bodyRoot body: ProductCheck;
}
