using Calcasa.Api.V0.Client;
using Calcasa.Api.V0.Api;
using Calcasa.Api.V0.Model;
using System;
using System.Collections.Generic;
using System.Net.Http;
using IdentityModel.Client;
using System.Threading.Tasks;

namespace ApiTest
{
    internal class OauthConfiguration : Configuration
    {
        private readonly string ClientId;
        private readonly string ClientSecret;
        private readonly string TokenUrl;
        private readonly HttpClient AuthClient;
        private TokenResponse Token;
        private DateTime ExpiresOn;

        public OauthConfiguration(string client_id,
            string client_secret,
            string token_url = "https://authentication.calcasa.nl/oauth2/v2.0/token",
            string basePath = "https://api.calcasa.nl") : base()
        {
            ClientId = client_id;
            ClientSecret = client_secret;
            TokenUrl = token_url;
            BasePath = basePath;
            AuthClient = new HttpClient();
        }
        private string accessToken;

        public override string AccessToken
        {
            get
            {
                UpdateAccessToken();
                return accessToken;
            }
            set
            {
                if (accessToken != value)
                {
                    accessToken = value;
                }
            }
        }

        /// <summary>
        /// Updates the access token Just-in-Time if it has expired or is not available.
        /// </summary>
        private void UpdateAccessToken()
        {
            if (Token != null)
            {
                if (!Token.IsError || ExpiresOn > DateTime.UtcNow)
                {
                    return;
                }
            }

            var request = new ClientCredentialsTokenRequest
            {
                Address = TokenUrl,
                ClientId = ClientId,
                ClientSecret = ClientSecret,
                ClientCredentialStyle = ClientCredentialStyle.AuthorizationHeader, // Recommended as opposed to secrets in body.
            };

            Token = AuthClient.RequestClientCredentialsTokenAsync(request).Result;

            if (Token.IsError)
            {
                throw new ApplicationException("Could not refresh token: [" + Token.ErrorType + "] " + Token.Error + "; " + Token.ErrorDescription);
            }
            else
            {
                ExpiresOn = DateTime.UtcNow.AddSeconds(Token.ExpiresIn);
                AccessToken = Token.AccessToken;
            }
        }
    }

    class Program
    {
        static async Task Main(string[] args)
        {
            var conf = new OauthConfiguration(
                client_id: "<client_id>",
                client_secret: "<client_secret>"
                );

            var client = new ApiClient(conf.BasePath);

            var aa = new AdressenApi(client, client, conf); //Using this constructor is required so the class defined above is not lost by merging configurations in the constructor without the explicit clients.

            var adres = new Adres(postcode: "2611EB", huisnummer: 41);
            var adresinfo = await aa.SearchAdresAsync(adres);

            Console.WriteLine(adresinfo);
        }
    }
}
