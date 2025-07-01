from datetime import datetime
from uuid import uuid4
from calcasa.api.configuration import Configuration
from calcasa.api.api_client import ApiClient

from oauthlib.oauth2 import BackendApplicationClient
from requests_oauthlib import OAuth2Session
import time

from calcasa.api.models.waardering import Waardering

from calcasa.api.api.adressen_api import AdressenApi
from calcasa.api.api.configuratie_api import ConfiguratieApi
from calcasa.api.api.facturen_api import FacturenApi
from calcasa.api.api.fotos_api import FotosApi
from calcasa.api.api.rapporten_api import RapportenApi
from calcasa.api.api.waarderingen_api import WaarderingenApi
from calcasa.api.models.aanvraagdoel import Aanvraagdoel
from calcasa.api.models.adres import Adres
from calcasa.api.models.callback import Callback
from calcasa.api.models.klantwaarde_type import KlantwaardeType
from calcasa.api.models.operation import Operation
from calcasa.api.models.operation_type import OperationType
from calcasa.api.models.product_type import ProductType
from calcasa.api.models.waardering_input_parameters import WaarderingInputParameters
from calcasa.api.models.waardering_status import WaarderingStatus
from calcasa.api.models.waardering_webhook_payload import WaarderingWebhookPayload
from calcasa.api.models.waardering_zoek_parameters import WaarderingZoekParameters


def handleAndPersistValuation(
    completeWaardering: Waardering, ra: RapportenApi, fa: FacturenApi, pa: FotosApi
):
    # For example inspect the Model output and persist it locally. (Remember that every field can be null).
    if completeWaardering.model:
        marktwaarde = completeWaardering.model.marktwaarde
        print(f"Marktwaarde = {marktwaarde}")

    # For select product types the result of the manual valuation is also available.
    if completeWaardering.taxatie:
        taxatiestatus = completeWaardering.taxatie.status
        print(f"Taxatiestatus = {taxatiestatus}")

    # Do we have a report?
    if (
        completeWaardering.rapport
        and completeWaardering.rapport.id != "00000000-0000-0000-0000-000000000000"
    ):

        report = ra.get_rapport(completeWaardering.rapport.id)
        fileName = f"calcasa-report-{completeWaardering.rapport.id}.jpg"

        print(f"Saved report {fileName}")
        # Process the PDF file if required.
        with open(fileName, "wb") as f:
            f.write(report)

    if (
        completeWaardering.factuur
        and completeWaardering.factuur.id != "00000000-0000-0000-0000-000000000000"
    ):

        factuur = fa.get_factuur(completeWaardering.factuur.id)
        fileName = f"calcasa-invoice-{completeWaardering.factuur.id}.jpg"

        print(f"Saved invoice {fileName}")
        # Process the PDF file if required.
        with open(fileName, "wb") as f:
            f.write(factuur)

    if completeWaardering.fotos:
        for foto in completeWaardering.fotos:
            if foto.id is not None:
                fotoFile = pa.get_foto(foto.id)
                fileName = f"calcasa-photo-{foto.id}.jpg"
                print(f"Saved photo {fileName}")
                # Process the image file if required.
                with open(fileName, "wb") as f:
                    f.write(fotoFile)


class OauthConfiguration(Configuration):

    def __init__(self, client_id, client_secret, token_url, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.client_id = client_id
        self.client_secret = client_secret
        self.token_url = token_url
        self.token = self.get_token()
        self.access_token = self.token["access_token"]

    def auth_settings(self):
        if self.token is not None:
            if self.token["expires_at"] > time.time():
                return super().auth_settings()

        self.token = self.get_token()
        self.access_token = self.token["access_token"]
        return super().auth_settings()

    def get_token(self):
        client = BackendApplicationClient(client_id=self.client_id)
        oauth = OAuth2Session(client=client)
        token = oauth.fetch_token(
            token_url=self.token_url,
            client_id=self.client_id,
            client_secret=self.client_secret,
        )
        return token


conf = OauthConfiguration(
    client_id="<client_id>",
    client_secret="<client_secret>",
    token_url="https://authentication.01.staging.calcasa.nl/oauth2/v2.0/token",
    host="https://api.staging.calcasa.nl/api/v1",  # NO TRAILING SLASH ON HOST!
)

ac = ApiClient(conf)

# Set the user agent for your application
ac.user_agent = "Python Application Name/0.0.1"

aa = AdressenApi(ac)
ca = ConfiguratieApi(ac)
wa = WaarderingenApi(ac)
ra = RapportenApi(ac)
fa = FacturenApi(ac)
pa = FotosApi(ac)

# --------------- #
# Adres endpoints #
# --------------- #

print(aa.get_adres(bag_nummeraanduiding_id=307200000435341))

adres = Adres(postcode="2547KE", huisnummer=259)  # Create Adres instance to be checked.
adresInfo = aa.search_adres(adres=adres)  # Check the adres against the API.

print(adresInfo)

idAdresInfo = aa.get_adres(
    307200000435341
)  # Get address information based on the BAG Nummeraanduiding ID.

print(idAdresInfo)

# ----------------------- #
# Configuration endpoints #
# ----------------------- #

# Please use the correct version string and make sure the URL is publicly resolvable and reachable by arbitrary IPs.
# This will result in requests going to https://test.calcasa.nl/callback/waardering for the waardering callback.
# You can also use query parameters like "https://test.calcasa.nl/callback.aspx?callbackType=" which would result in the final URl being = https://test.calcasa.nl/callback.aspx?callbackType=waardering for the waardering callback.
callback = Callback(version="v1", url="https://test.calcasa.nl/callback/")
configs = ca.update_callbacks(callback=callback)

for config in configs:
    print(config)

# This is a test so we will reset it to an empty value to disable the webhook. If you are not returning HTTP 200, please disable the unused callback to reduce request spam from our infrastructure to the endpoint configured.
callbackReset = Callback(version="v1", url="")
configsReset = ca.update_callbacks(callback=callbackReset)

for config in configsReset:
    print(config)

# ---------------------- #
# Waarderingen endpoints #
# ---------------------- #

# If you need to create a valuation this is a multi step process.

waarderingInput = WaarderingInputParameters(
    productType=ProductType.DESKTOPTAXATIE,
    hypotheekwaarde=205000,
    aanvraagdoel=Aanvraagdoel.AANKOOPNIEUWEWONING,
    klantwaarde=305000,
    klantwaardeType=KlantwaardeType.KOOPSOM,
    isBestaandeWoning=True,
    bagNummeraanduidingId=adresInfo.bag_nummeraanduiding_id,
    isNhg=False,
    isErfpacht=False,
)

waarderingOutput = wa.create_waardering(waardering_input_parameters=waarderingInput)

print(waarderingOutput)

# Save the Id for future reference.
id = waarderingOutput.id

# Eventually check if the address is correct in the output and then confirm the valuation. This can mean presenting the information to the user and asking them to confirm for example.

# Now that we want to confirm the valuation we are going to patch the status to open.

operations = [Operation(path="/status", op=OperationType("replace"), value="open")]

waarderingOutputAfterPatch = wa.patch_waarderingen(id, list_operation=operations)

# Now is a good time to persist the Id and the other information to a database.

# Some time later. (Note this sleep simulation only works for test requests, in the real world valuations might be much slower depending on the ProductType.
print("Waiting 10 seconds...")
time.sleep(10)

# The webhook will fire when the status has changed succesfully.
# Lets simulate a Webhook payload and process it.

webhookPayload = WaarderingWebhookPayload(
    callbackName="waardering",
    eventId=str(
        uuid4()
    ),  # This is the Id of the actual upstream event, this stays the same across retries. (Save this if your handling of this webhook is not idempotent)
    waarderingId=id,  # This is the valuation id.
    oldStatus=WaarderingStatus.OPEN,
    newStatus=WaarderingStatus.VOLTOOID,
    timestamp=datetime.now(),  # This is the timestamp of the original event.
    isTest=True,
)

# Here follow some example procesing code for example to download the report, invoice and/or photos.

if (
    webhookPayload.new_status == WaarderingStatus.VOLTOOID
    and webhookPayload.waardering_id is not None
):
    # The valuation is complete and will now have full output, lets request the valuation
    completeWaardering = wa.get_waardering(webhookPayload.waardering_id)
    handleAndPersistValuation(completeWaardering, ra, fa, pa)


print(f"Done with valuation {id}.")


# If instead you want to find the waarderingen objects and you don't have the Ids this endpoint lets your search for them. The ProductType and BAG Id are required, we can reuse the results from our previous SearchAdres call.
searchParameters = WaarderingZoekParameters(
    productType=ProductType.DESKTOPTAXATIE,
    bagNummeraanduidingId=adresInfo.bag_nummeraanduiding_id,
)
waarderingen = wa.search_waarderingen(waardering_zoek_parameters=searchParameters)

for waardering in waarderingen:
    # This would give you the oppurtunity to grab the lastest one for example or filter further to pick the one you need.
    print(f"Found = {waardering.id}")

if len(waarderingen) > 0:
    # This is how you get the latest valuation to for example download the Report.
    lastValuationForAddress = sorted(
        waarderingen, reverse=True, key=lambda w: w.aangemaakt
    )[0]

    print(f"Last valuation = {lastValuationForAddress.id}")
    handleAndPersistValuation(lastValuationForAddress, ra, fa, pa)
