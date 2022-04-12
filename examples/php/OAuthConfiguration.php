<?php
require_once("vendor/autoload.php");

use Calcasa\Api\Configuration;
use League\OAuth2\Client\Provider\GenericProvider;

class OAuthConfiguration extends Configuration {

    // @var GenericProvider
    protected $provider = null;

    // @var 
    protected $token = null;

    public function __construct($client_id, $client_secret,
    $authorize_url = "",
    $token_url = "https://authentication.calcasa.nl/oauth2/v2.0/token",
    $resource_owner_url = "",
    $base_path = "https://api.calcasa.nl"){
        parent::__construct();
        $this->provider = new GenericProvider([
            'clientId'                => $client_id,    // The client ID assigned to you by the provider
            'clientSecret'            => $client_secret,    // The client password assigned to you by the provider
            'urlAccessToken'          => $token_url,
            'urlAuthorize'            => $authorize_url,
            'urlResourceOwnerDetails' => $resource_owner_url
        ]);
        $this->setHost($base_path);
    }

    private function refreshToken(){
        try {
            $this->token = $this->provider->getAccessToken('client_credentials');
        }
        catch (League\OAuth2\Client\Provider\Exception\IdentityProviderException $e) {

            // Failed to get the access token or user details.
            exit($e->getMessage());
    
        }
        $this->setAccessToken($this->token->getToken());
    }

    /**
     * Gets the access token for OAuth and refreshes it if required
     *
     * @return string Access token for OAuth
     */
    public function getAccessToken()
    {
        if($this->token == null || $this->token->hasExpired()){
            $this->refreshToken();
        }
        return parent::getAccessToken();
    }
}

