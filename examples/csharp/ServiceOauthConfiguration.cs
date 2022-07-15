using Calcasa.Api.Client;
using Calcasa.Api.Api;
using Calcasa.Api.Model;
using System;
using System.Collections.Generic;
using System.Net.Http;
using IdentityModel.Client;
using System.Threading.Tasks;

namespace ApiTest;

internal class ServiceOAuthConfiguration : Configuration
{
    private readonly string ClientId;
    private readonly string ClientSecret;
    private readonly string TokenUrl;
    private readonly HttpClient AuthClient;
    private TokenResponse Token;
    private DateTime ExpiresOn;

    public ServiceOAuthConfiguration(string client_id,
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