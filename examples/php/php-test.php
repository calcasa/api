<?php
error_reporting(E_ALL & ~E_DEPRECATED);
require_once("vendor/autoload.php");
require_once("OAuthConfiguration.php");

use GuzzleHttp\Client;
use Calcasa\Api;

$conf = new OAuthConfiguration(
    client_id:'<client_id>',
    client_secret:'<client_secret>',
    base_path: "https://api.staging.calcasa.nl/api/v1",
    token_url: "https://authentication.01.staging.calcasa.nl/oauth2/v2.0/token");

$conf->setUserAgent("PHP Application Name/0.0.1");

$client = new Client();

// Reuse the client and the configuration.
$aa = new Api\Api\AdressenApi($client, $conf);
$ca = new Api\Api\ConfiguratieApi($client, $conf);
$wa = new Api\Api\WaarderingenApi($client, $conf);
$ra = new Api\Api\RapportenApi($client, $conf);
$fa = new Api\Api\FacturenApi($client, $conf);
$pa = new Api\Api\FotosApi($client, $conf);

try{
/* --------------- *
* Adres endpoints *
* --------------- */

$adres = new Api\Model\Adres(array("postcode"=>"2547KE", "huisnummer" => 259)); // Create Adres instance to be checked.            
$adresinfo = $aa->searchAdresAsync($adres)->wait(); // Check the adres against the API.

echo $adresinfo.PHP_EOL;

$officeAddressInfo = $aa->getAdresAsync(307200000435341)->wait(); // Get address information based on the BAG Nummeraanduiding ID.

echo $officeAddressInfo.PHP_EOL;

/* ----------------------- *
* Configuration endpoints *
* ----------------------- */

// Please use the correct version string and make sure the URL is publicly resolvable and reachable by arbitrary IPs.
// This will result in requests going to https://test.calcasa.nl/callback/waardering for the waardering callback.
// You can also use query parameters like "https://test.calcasa.nl/callback.aspx?callbackType=" which would result in the final URl being: https://test.calcasa.nl/callback.aspx?callbackType=waardering for the waardering callback.
$callback = new Api\Model\Callback(array('version'=>"v1", 'url'=>"https://test.calcasa.nl/callback/")); 
$configs = $ca->updateCallbacksAsync($callback)->wait();

foreach ($configs as $config)
{
    echo $config.PHP_EOL;
}

//This is a test so we will reset it to an empty value to disable the webhook. If you are not returning HTTP 200, please disable the unused callback to reduce request spam from our infrastructure to the endpoint configured.
$callbackReset = new Api\Model\Callback(array('version'=>"v1", 'url'=>''));
$configsReset = $ca->updateCallbacksAsync($callbackReset)->wait();

foreach ($configsReset as $config)
{
    echo $config.PHP_EOL;
}

/* ---------------------- *
* Waarderingen endpoints *
* ---------------------- */

// If you need to create a new valuation this is a multi step process.

$waarderingInput = new Api\Model\WaarderingInputParameters(array(
'productType'=> Api\Model\ProductType::DESKTOP_TAXATIE,
'hypotheekwaarde'=> 205000,
'aanvraagdoel'=> Api\Model\Aanvraagdoel::AANKOOP_NIEUWE_WONING,
'klantwaarde'=> 305000,
'klantwaardeType'=> Api\Model\KlantwaardeType::KOOPSOM,
'isBestaandeWoning'=> true,
'bagNummeraanduidingId'=> $adresinfo->getBagNummeraanduidingId(),
'isNhg'=> false,
'isErfpacht'=> false
));

$waarderingOutput = $wa->createWaarderingAsync($waarderingInput)->wait();

echo $waarderingOutput.PHP_EOL;

//Save the Id for future reference.
$id = $waarderingOutput->getId();

// Eventually check if the address is correct in the output and then confirm the valuation. This can mean presenting the information to the user and asking them to confirm for example.

// Now that we want to confirm the valuation we are going to patch the status to open.
$jsonPatch = array(
    new Api\Model\Operation(array(
        'path' => "/status",
        'op' => Api\Model\OperationType::REPLACE,
        'value' => "open"
    ))
);

$waarderingOutputAfterPatch = $wa->patchWaarderingenAsync($id, $jsonPatch)->wait();

// Now is a good time to persist the Id and the other information to a database.

// Some time later. (Note this sleep simulation only works for test requests, in the real world valuations might be much slower depending on the ProductType.
echo "Waiting 10 seconds...".PHP_EOL;
sleep(10);

// The webhook will fire when the status has changed succesfully.
// Lets simulate a Webhook payload and process it.

$webhookPayload = new Api\Model\WaarderingWebhookPayload(array(
'eventId' => guid(), // This is the Id of the actual upstream event, this stays the same across retries. (Save this if your handling of this webhook is not idempotent)
'waarderingId' => $id, // This is the valuation id.
'oldStatus' => Api\Model\WaarderingStatus::OPEN,
'newStatus' => Api\Model\WaarderingStatus::VOLTOOID,
'timestamp' => new DateTime(timezone: new DateTimeZone('UTC')), // This is the timestamp of the original event.
'isTest' => true));

// Here follow some example procesing code for example to download the report, invoice and/or photos.

if($webhookPayload->getNewStatus() == Api\Model\WaarderingStatus::VOLTOOID)
{
    // The valuation is complete and will now have full output, lets request the valuation
    $completeWaardering = $wa->getWaarderingAsync($webhookPayload->getWaarderingId())->wait();
    HandleAndPersistValuation($completeWaardering, $ra,$fa,$pa);
}

echo "Done with valuation {$id}.".PHP_EOL;


//If instead you want to find the waarderingen objects and you don't have the Ids this endpoint lets your search for them. The ProductType and BAG Id are required, we can reuse the results from our previous SearchAdres call.
$searchParameters = new Api\Model\WaarderingZoekParameters(array(
    'productType' => Api\Model\ProductType::DESKTOP_TAXATIE, 
    'bagNummeraanduidingId' => $adresinfo->getBagNummeraanduidingId()
));
$waarderingen = $wa->searchWaarderingenAsync($searchParameters)->wait();

foreach ($waarderingen as $waardering)
{
    // This would give you the oppurtunity to grab the lastest one for example or filter further to pick the one you need.
    echo "Found: {$waardering->getId()}".PHP_EOL;
}
if (count($waarderingen)>0)
{
    // Sort in place descending on creation date.
    usort($waarderingen, function ($item1, $item2) {
        return $item2->getAangemaakt() <=> $item1->getAangemaakt();
    });
    $lastValuationForAddress = $waarderingen[0];

    echo "Last valuation: {$lastValuationForAddress->getId()}".PHP_EOL;
    HandleAndPersistValuation($lastValuationForAddress, $ra, $fa, $pa);
}
} catch(Api\ApiException $e){
    echo $e;
    echo "Headers:".PHP_EOL;
    var_dump($e->getResponseHeaders());
    echo PHP_EOL;
    echo "Body:".PHP_EOL;
    var_dump($e->getResponseBody());
    echo PHP_EOL;
}


function HandleAndPersistValuation(Api\Model\Waardering $completeWaardering, Api\Api\RapportenApi $ra, Api\Api\FacturenApi $fa, Api\Api\FotosApi $pa) {
    // For example inspect the Model output and persist it locally. (Remember that every field can be null).
    if($completeWaardering->offsetExists('model')){
        $marktwaarde = $completeWaardering->getModel()->getMarktwaarde();
        echo "Marktwaarde: {$marktwaarde}".PHP_EOL;
    }

    //For select product types the result of the manual valuation is also available.
    if($completeWaardering->offsetExists('taxatie')){
        $taxatiestatus = $completeWaardering->getTaxatie()->getStatus();
        echo "Taxatiestatus: {$taxatiestatus}".PHP_EOL;
    }
    // Do we have a report?
    if ($completeWaardering->offsetExists('rapport'))
    {
        // Use getRapportAsyncWithHttpInfo if you want access to the Headers (like Content-Type and Content-Disposition)
        $report = $ra->getRapportAsync($completeWaardering->getRapport()->getId())->wait();
        echo "Saves report to ".$report->getPathname().PHP_EOL;
    }

    // Do we have an invoice?
    if ($completeWaardering->offsetExists('factuur'))
    {
        // Use getFactuurAsyncWithHttpInfo if you want access to the Headers (like Content-Type and Content-Disposition)
        $invoice = $fa->getFactuurAsync($completeWaardering->getFactuur()->getId())->wait();
        echo "Saves invoice to ".$invoice->getPathname().PHP_EOL;
    }

    // Do we have a photos
    if ($completeWaardering->offsetExists('fotos'))
    {
        foreach($completeWaardering->getFotos() as $foto){
            $fotoFile = $pa->getFotoAsync($foto->getId())->wait();
            echo "Saves foto to ".$fotoFile->getPathname().PHP_EOL;
        }
    }
}

function guid(){
    if (function_exists('com_create_guid') === true)
        return trim(com_create_guid(), '{}');

    $data = openssl_random_pseudo_bytes(16);
    $data[6] = chr(ord($data[6]) & 0x0f | 0x40);
    $data[8] = chr(ord($data[8]) & 0x3f | 0x80);
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
}