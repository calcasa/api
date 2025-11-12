import "@typespec/openapi";
import "@typespec/openapi3";

using OpenAPI;

/**
 * English: Request Goal.
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `onbekend` | English: Unknown. |
 * | `aankoopNieuweWoning` | English: New Home Purchase. |
 * | `overbruggingsfinanciering` | English: Bridge Financing. |
 * | `hypotheekOversluiten` | English: Refinancing Mortgage. |
 * | `hypotheekOphogen` | English: Increasing Mortage. |
 * | `hypotheekWijziging` | English: Changing Mortgage. |
 * | `hypotheekrenteWijzigen` | English: Change Mortgage Intrest. |
 *
 *
 *
 */
@extension("x-zero-based-enum", true)
enum Aanvraagdoel {
  onbekend,
  aankoopNieuweWoning,
  overbruggingsfinanciering,
  hypotheekOversluiten,
  hypotheekOphogen,
  hypotheekWijziging,
  hypotheekrenteWijzigen,
}

/**
 *
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `geenData` | Er is geen data beschikbaar over deze bodem. |
 * | `onbekend` | De status van deze bodem is niet bekend. |
 * | `nietVervuild` | De bodem is niet vervuild. |
 * | `nietErnstig` | De bodem is niet ernstig vervuild. |
 * | `potentieelErnstig` | De bodem is potentieel ernstig veruild. |
 * | `ernstig` | De bodem is ernstig veruild. |
 *
 *
 *
 */
@extension("x-zero-based-enum", true)
enum BodemStatusType {
  geenData,
  onbekend,
  nietVervuild,
  nietErnstig,
  potentieelErnstig,
  ernstig,
}

/**
 * Reden voor het niet voldoen aan de business rules.
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `geenWaardebepalingMogelijk` | De ingevoerde woning kan modelmatig niet goed genoeg worden vastgesteld. |
 * | `geenBestaandeWoning` | Geen bestaande koopwoning. |
 * | `fouteOfOntbrekendeInvoer` | Noodzakelijke invoer ontbreekt of is foutief ingevoerd. |
 * | `calcasaWaardeTeHoog` | Calcasa-waarde is te hoog volgens de business rules. |
 * | `ltvTeHoog` | Loan-to-value is te hoog volgens de business rules. |
 * | `hypotheekTeHoog` | Hypotheekbedrag is te hoog volgens de business rules. |
 * | `woningtypeIncorrect` | Woningtype is incorrect volgens de business rules. |
 * | `calcasaWaardeTeLaag` | Calcasa-waarde is te laag volgens de business rules. |
 * | `calcasaWaardeTeHoogVoorNhg` | Calcasa-waarde is te hoog voor een NHG-waardering volgens de business rules. |
 * | `calcasaWaardeEnKoopsomTeHoogVoorNhg` | Calcasa-waarde en ingevoerde koopsom zijn te hoog voor een NHG-waardering volgens de business rules. |
 * | `ltvTeHoogOverbrugging` | Loan-to-value is te hoog voor deze overbrugging volgens de business rules. |
 * | `geenEigenBewoning` | Woning is niet bestemd voor eigen bewoning. |
 * | `incorrecteErfpacht` | Erfpachtsituatie is niet toegestaan volgens de business rules. |
 */
@extension("x-zero-based-enum", true)
enum BusinessRulesCode {
  geenWaardebepalingMogelijk,
  geenBestaandeWoning,
  fouteOfOntbrekendeInvoer,
  calcasaWaardeTeHoog,
  ltvTeHoog,
  hypotheekTeHoog,
  woningtypeIncorrect,
  calcasaWaardeTeLaag,
  calcasaWaardeTeHoogVoorNhg,
  calcasaWaardeEnKoopsomTeHoogVoorNhg,
  ltvTeHoogOverbrugging,
  geenEigenBewoning,
  incorrecteErfpacht,
}

/**
 *
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `onbekend` |  |
 * | `g` |  |
 * | `f` |  |
 * | `e` |  |
 * | `d` |  |
 * | `c` |  |
 * | `b` |  |
 * | `a` |  |
 * | `a1` | A+. |
 * | `a2` | A++. |
 * | `a3` | A+++. |
 * | `a4` | A++++. |
 *
 */
@extension("x-zero-based-enum", true)
enum Energielabel {
  onbekend,
  g,
  f,
  e,
  d,
  c,
  b,
  a,
  a1,
  a2,
  a3,
  a4,
}

/**
 * Bron waar de funderingsinformatie opgehaald is.
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `calcasa` | Calcasa data. |
 * | `fundermaps` | Fundermaps data. |
 *
 */
@extension("x-zero-based-enum", true)
enum FunderingDataBron {
  calcasa,
  fundermaps,
}

/**
 * Herstel-types voor funderingen.
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `onbekendHerstelType` | Hersteltype is onbekend. |
 * | `vergunning` | O.b.v. vergunning. |
 * | `funderingRapport` | O.b.v. fundering-rapport. |
 * | `archiefRapport` | O.b.v. archief-rapport. |
 * | `eigenaarBewijs` | O.b.v. bewijs van eigenaar. |
 *
 */
@extension("x-zero-based-enum", true)
enum FunderingHerstelType {
  onbekendHerstelType,
  vergunning,
  funderingRapport,
  archiefRapport,
  eigenaarBewijs,
}

/**
 * Indicatie voor een funderingsrisico.
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `onbekend` | Risico klasse onbekend. |
 * | `laag` | Laagste risico. |
 * | `gemiddeld` | Gemiddeld risico. |
 * | `hoog` | Hoogste risico. |
 *
 */
@extension("x-zero-based-enum", true)
enum FunderingRisicoLabel {
  onbekend,
  laag,
  gemiddeld,
  hoog,
}

/**
 * Bron voor funderingsinformatie.
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `onbekend` | Onbekende bron. |
 * | `model` | Modelmatig. |
 * | `document` | Uit een document. |
 * | `bouweenheid` | Op basis van woningen in hetzelfde woonblok. |
 *
 */
@extension("x-zero-based-enum", true)
enum FunderingSoortBron {
  onbekend,
  `model`,
  document,
  bouweenheid,
}

/**
 * Funderingstypes.
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `onbekendFunderingType` | Onbekend fundering-type. |
 * | `hout` | Hout. |
 * | `houtAmsterdam` | Hout, Amsterdamse variant. |
 * | `houtRotterdam` | Hout, Rotterdamse variant. |
 * | `beton` | Beton. |
 * | `nietOnderheid` | Niet onderheid. |
 * | `nietOnderheidGemetseld` | Niet onderheid, gemetseld. |
 * | `nietOnderheidStroken` | Niet onderheid, stroken. |
 * | `nietOnderheidPlaat` | Niet onderheid, plaat. |
 * | `nietOnderheidBetonplaat` | Niet onderheid, betonplaat. |
 * | `nietOnderheidSlieten` | Niet onderheid, slieten. |
 * | `houtOplanger` | Hout met oplanger. |
 * | `betonVerzwaard` | Beton verzwaard. |
 * | `gecombineerd` | Gecombineerd. |
 * | `staal` | Stalen buispaal. |
 * | `houtAmsterdamRotterdam` | Houten paal, Rotterdam/Amsterdam methode. |
 * | `houtRotterdamSpaarboog` | Houten paal, Rotterdam methode met spaarboog. |
 * | `houtAmsterdamSpaarboog` | Houten paal, Amsterdam methode met spaarboog. |
 *
 */
@extension("x-zero-based-enum", true)
enum FunderingType {
  onbekendFunderingType,
  hout,
  houtAmsterdam,
  houtRotterdam,
  beton,
  nietOnderheid,
  nietOnderheidGemetseld,
  nietOnderheidStroken,
  nietOnderheidPlaat,
  nietOnderheidBetonplaat,
  nietOnderheidSlieten,
  houtOplanger,
  betonVerzwaard,
  gecombineerd,
  staal,
  houtAmsterdamRotterdam,
  houtRotterdamSpaarboog,
  houtAmsterdamSpaarboog,
}

/**
 *
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `onbekend` |  |
 * | `koopsom` |  |
 * | `taxatiewaarde` |  |
 * | `wozWaarde` |  |
 * | `eigenWaardeinschatting` |  |
 *
 */
@extension("x-zero-based-enum", true)
enum KlantwaardeType {
  onbekend,
  koopsom,
  taxatiewaarde,
  wozWaarde,
  eigenWaardeinschatting,
}

/**
 *
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `geen` | De input was correct. |
 * | `gecorrigeerd` | De input was gecorrigeerd. |
 * | `onbekend` | De input is onbekend en kon niet gevonden of gecorrigeerd worden. |
 * | `ontbreekt` | De input was leeg en is wel nodig voor een succesvolle zoekopdracht. |
 *
 */
@extension("x-zero-based-enum", true)
enum Notitie {
  geen,
  gecorrigeerd,
  onbekend,
  ontbreekt,
}

/**
 *
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `add` |  |
 * | `remove` |  |
 * | `replace` |  |
 * | `move` |  |
 * | `copy` |  |
 * | `test` |  |
 * | `invalid` |  |
 *
 */
@extension("x-zero-based-enum", true)
enum OperationType {
  add,
  remove,
  replace,
  move,
  copy,
  test,
  invalid,
}

/**
 * Het product type voor een waardering. Deze moeten handmatig aangezet worden voor de gebruikte credentails.
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `onbekend` | Geen geldige invoer. Onbekend product type. |
 * | `modelwaardeCalcasa` | Niet beschikbaar op dit moment.<br>            Modelwaarde aanvraag met Calcasa Waardebepalingrapport. |
 * | `modelwaardeRisico` | Modelwaarde aanvraag met risicorapport. |
 * | `modelwaardeDesktopTaxatie` | Modelwaarde aanvraag met Desktop Taxatie Beknoptwaarderapport. |
 * | `desktopTaxatie` | Desktop taxatie aanvraag met Desktop Taxatie rapport. |
 * | `desktopTaxatieHerwaardering` | Desktop taxatie aanvraag met Desktop Taxatie rapport voor herwaarderingen. |
 *
 */
@extension("x-zero-based-enum", true)
enum ProductType {
  onbekend,
  modelwaardeCalcasa,
  modelwaardeRisico,
  modelwaardeDesktopTaxatie,
  desktopTaxatie,
  desktopTaxatieHerwaardering,
}

/**
 *
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `nietGecontroleerd` | Status is onbekend of niet van toepassing. |
 * | `goedgekeurd` | De waardering is geaccepteerd door een taxateur. |
 * | `afgekeurd` | De waardering is afgewezen door een taxateur. |
 *
 */
@extension("x-zero-based-enum", true)
enum Taxatiestatus {
  nietGecontroleerd,
  goedgekeurd,
  afgekeurd,
}

/**
 *
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `onbekend` | Bijzonderheden onbekend. |
 * | `executieverkoop` | Een indicatie dat het object is verkocht via een executieveiling. |
 * | `familieverkoop` | Een indicatie dat de transactie is geregistreerd als familieverkoop. |
 * | `meerOnroerendGoed` | Een indicatie dat de transactie meerdere percelen bevat. |
 * | `zittendeHuurder` | Een indicatie dat de transactie is geregistreerd als verkoop aan de zittende huurder. |
 * | `verkoperNietNatuurlijk` | Een indicatie dat de verkoper een niet-natuurlijke persoon is. |
 * | `koperNietNatuurlijk` | Een indicatie dat de koper een niet-natuurlijke persoon is. |
 * | `nietWoning` | Een indicatie dat het object geregistreerd is als niet-woning. |
 * | `erfdienstbaarheid` | Een indicatie dat er een erfdienstbaarheid op het object gevestigd is. |
 *
 */
@extension("x-zero-based-enum", true)
enum VerkoopBijzonderheden {
  onbekend,
  executieverkoop,
  familieverkoop,
  meerOnroerendGoed,
  zittendeHuurder,
  verkoperNietNatuurlijk,
  koperNietNatuurlijk,
  nietWoning,
  erfdienstbaarheid,
}

/**
 *
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `onbekend` | Status onbekend. |
 * | `initialiseren` | Deze waardering is geinitialiseerd maar moet nog bevestigd worden. |
 * | `open` | Deze waardering is bevestigd maar moet nog uitgevoerd worden. |
 * | `voltooid` | Deze waardering is voltooid. |
 * | `opgewaardeerd` | Deze waardering is geupgrade naar een ander waardering type. |
 * | `ongeldig` | Deze waardering is niet geldig, bijvoorbeeld omdat hij niet door de business rules is gekomen. |
 * | `verlopen` | Deze waardering is verlopen omdat hij niet op tijd bevestigd is. |
 * | `error` | Er is iets mis gegaan voor deze waardering. |
 * | `inBehandeling` | Deze waardering is in behandeling door het systeem. |
 *
 */
@extension("x-zero-based-enum", true)
enum WaarderingStatus {
  onbekend,
  initialiseren,
  open,
  voltooid,
  opgewaardeerd,
  ongeldig,
  verlopen,
  error,
  inBehandeling,
}

/**
 * Woningtypes zoals gedefinieerd in het Calcasa-model.
 * | Waarde | Omschrijving |
 * | --- | --- |
 * | `onbekend` | Onbekend woning type. |
 * | `vrijstaand` | Vrijstaande woning. |
 * | `halfVrijstaand` | Half-vrijstaande woning / twee-onder-een-kap. |
 * | `hoekwoning` | Hoekwoning. |
 * | `tussenwoning` | Tussenwoning. |
 * | `galerijflat` | Galerijflat. |
 * | `portiekflat` | Portiekflat. |
 * | `maisonnette` | Maisonette. |
 * | `bovenwoning` | Bovenwoning. |
 * | `benedenwoning` | Benedenwoning. |
 *
 */
@extension("x-zero-based-enum", true)
enum WoningType {
  onbekend,
  vrijstaand,
  halfVrijstaand,
  hoekwoning,
  tussenwoning,
  galerijflat,
  portiekflat,
  maisonnette,
  bovenwoning,
  benedenwoning,
}
