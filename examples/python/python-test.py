from calcasa.api import ApiClient, Configuration
from calcasa.api.models import Adres
from calcasa.api.apis import AdressenApi

from oauthlib.oauth2 import BackendApplicationClient
from requests_oauthlib import OAuth2Session
import time

class OauthConfiguration(Configuration):

    def __init__(self, client_id, client_secret, token_url, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.client_id = client_id
        self.client_secret = client_secret
        self.token_url = token_url
        self.token = self.get_token()
        self.access_token = self.token['access_token']

    def auth_settings(self):
        if self.token is not None:
            if self.token['expires_at'] > time.time():
                return super().auth_settings()

        self.token = self.get_token()
        self.access_token = self.token['access_token']
        return super().auth_settings()

    def get_token(self):
        client = BackendApplicationClient(client_id=self.client_id)
        oauth = OAuth2Session(client=client)
        token = oauth.fetch_token(
            token_url=self.token_url,
            client_id=self.client_id,
            client_secret=self.client_secret)
        return token


conf = OauthConfiguration(
    client_id='<client_id>',
    client_secret='<client_secret>',
    token_url='https://authentication.calcasa.nl/oauth2/v2.0/token',
    host="https://api.calcasa.nl", # NO TRAILING SLASH ON HOST!
    discard_unknown_keys=True) # Important to be tolerant of missing fields, empty fields or new fields.

ac = ApiClient(conf)

# Set the user agent for your application
ac.user_agent = "Python Application Name/0.0.1"

aa = AdressenApi(ac)

print(aa.get_adres(bag_nummeraanduiding_id=489200000253543))

adres = Adres(postcode="2624NM", huisnummer=73)
print(aa.search_adres(adres=adres))
