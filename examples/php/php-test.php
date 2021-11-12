<?php

require_once("vendor/autoload.php");

use GuzzleHttp\Client;
use Calcasa\Api\V0;
use Calcasa\Api\V0\Api;
use Calcasa\Api\V0\Model;

$conf = V0\Configuration::getDefaultConfiguration();

$conf->setHost("https://api.calcasa.nl");

$conf->setAccessToken("<access_token>");

$conf->setUserAgent("PHP Application Name/0.0.1");

$client = new Client();

$adressen = new Api\AdressenApi($client, $conf);

try {
    $result = $adressen->getAdres(489200000253543);
    print_r($result);
} catch (Exception $e) {
    echo 'Exception when calling AdressenApi->getAdres: ', $e->getMessage(), PHP_EOL;
}

$adres = new Model\Adres(array("postcode"=>"2624NM", "huisnummer"=>73));

print_r($adressen->searchAdres($adres));