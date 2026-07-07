from calcasa.api.configuration import Configuration

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