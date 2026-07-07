from datetime import datetime
from uuid import uuid4
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

from common import create_api_client, load_example_environment

load_example_environment()


def handle_and_persist_valuation(
    complete_waardering: Waardering, ra: RapportenApi, fa: FacturenApi, pa: FotosApi
):
    # Helper for post-processing: inspect valuation output and persist related artifacts.
    # For example inspect the Model output and persist it locally. (Remember that every field can be null).
    if complete_waardering.model:
        marktwaarde = complete_waardering.model.marktwaarde
        print(f"Marktwaarde = {marktwaarde}")

    # For select product types the result of the manual valuation is also available.
    if complete_waardering.taxatie:
        taxatiestatus = complete_waardering.taxatie.status
        print(f"Taxatiestatus = {taxatiestatus}")

    # Do we have a report?
    if (
        complete_waardering.rapport
        and complete_waardering.rapport.id != "00000000-0000-0000-0000-000000000000"
    ):

        report = ra.get_rapport(complete_waardering.rapport.id)
        file_name = f"calcasa-report-{complete_waardering.rapport.id}.jpg"

        print(f"Saved report {file_name}")
        # Process the PDF file if required.
        with open(file_name, "wb") as f:
            f.write(report)

    if (
        complete_waardering.factuur
        and complete_waardering.factuur.id != "00000000-0000-0000-0000-000000000000"
    ):

        factuur = fa.get_factuur(complete_waardering.factuur.id)
        file_name = f"calcasa-invoice-{complete_waardering.factuur.id}.jpg"

        print(f"Saved invoice {file_name}")
        # Process the PDF file if required.
        with open(file_name, "wb") as f:
            f.write(factuur)

    if complete_waardering.fotos:
        for foto in complete_waardering.fotos:
            if foto.id is not None:
                foto_file = pa.get_foto(foto.id)
                file_name = f"calcasa-photo-{foto.id}.jpg"
                print(f"Saved photo {file_name}")
                # Process the image file if required.
                with open(file_name, "wb") as f:
                    f.write(foto_file)



# Shared setup: validates required env values and configures OAuth + API client.
ac = create_api_client()

# Typed API clients used in the workflow below.
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
adres_info = aa.search_adres(adres=adres)  # Check the adres against the API.

print(adres_info)

id_adres_info = aa.get_adres(
    307200000435341
)  # Get address information based on the BAG Nummeraanduiding ID.

print(id_adres_info)

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
callback_reset = Callback(version="v1", url="")
configs_reset = ca.update_callbacks(callback=callback_reset)

for config in configs_reset:
    print(config)

# ---------------------- #
# Waarderingen endpoints #
# ---------------------- #

# If you need to create a valuation this is a multi step process.

# Step 1: create the valuation request.
waardering_input = WaarderingInputParameters(
    productType=ProductType.DESKTOPTAXATIE,
    hypotheekwaarde=205000,
    aanvraagdoel=Aanvraagdoel.AANKOOPNIEUWEWONING,
    klantwaarde=305000,
    klantwaardeType=KlantwaardeType.KOOPSOM,
    isBestaandeWoning=True,
    bagNummeraanduidingId=adres_info.bag_nummeraanduiding_id,
    isNhg=False,
    isErfpacht=False,
    heeftAflossingsvrijDeel=False
)

waardering_output = wa.create_waardering(waardering_input_parameters=waardering_input)

print(waardering_output)

# Save the Id for future reference.
id = waardering_output.id

# Eventually check if the address is correct in the output and then confirm the valuation. This can mean presenting the information to the user and asking them to confirm for example.

# Now that we want to confirm the valuation we are going to patch the status to open.

operations = [Operation(path="/status", op=OperationType("replace"), value="open")]

# Step 2: patch status to open, which effectively confirms the request lifecycle.
waardering_output_after_patch = wa.patch_waarderingen(id, list_operation=operations)

# Now is a good time to persist the Id and the other information to a database.

# Some time later. (Note this sleep simulation only works for test requests, in the real world valuations might be much slower depending on the ProductType.
print("Waiting 10 seconds...")
time.sleep(10)

# The webhook will fire when the status has changed succesfully.
# Lets simulate a Webhook payload and process it.

webhook_payload = WaarderingWebhookPayload(
    callbackName="waardering",
    eventId=uuid4(),  # This is the Id of the actual upstream event, this stays the same across retries. (Save this if your handling of this webhook is not idempotent)
    waarderingId=id,  # This is the valuation id.
    oldStatus=WaarderingStatus.OPEN,
    newStatus=WaarderingStatus.VOLTOOID,
    timestamp=datetime.now(),  # This is the timestamp of the original event.
    isTest=True,
)

# Here follow some example procesing code for example to download the report, invoice and/or photos.

if (
    webhook_payload.new_status == WaarderingStatus.VOLTOOID
    and webhook_payload.waardering_id is not None
):
    # Step 3: after completion, fetch full valuation output and process related files.
    # The valuation is complete and will now have full output, lets request the valuation
    complete_waardering = wa.get_waardering(webhook_payload.waardering_id)
    handle_and_persist_valuation(complete_waardering, ra, fa, pa)


print(f"Done with valuation {id}.")


# If instead you want to find the waarderingen objects and you don't have the Ids this endpoint lets your search for them. The ProductType and BAG Id are required, we can reuse the results from our previous SearchAdres call.
search_parameters = WaarderingZoekParameters(
    productType=ProductType.DESKTOPTAXATIE,
    bagNummeraanduidingId=adres_info.bag_nummeraanduiding_id,
)
waarderingen = wa.search_waarderingen(waardering_zoek_parameters=search_parameters)

for waardering in waarderingen:
    # This would give you the oppurtunity to grab the lastest one for example or filter further to pick the one you need.
    print(f"Found = {waardering.id}")

if len(waarderingen) > 0:
    # This is how you get the latest valuation to for example download the Report.
    last_valuation_for_address = sorted(
        waarderingen, reverse=True, key=lambda w: w.aangemaakt
    )[0]

    print(f"Last valuation = {last_valuation_for_address.id}")
    handle_and_persist_valuation(last_valuation_for_address, ra, fa, pa)
