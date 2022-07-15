using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

using Calcasa.Api.Client;

using IdentityModel;
using IdentityModel.OidcClient;
using IdentityModel.OidcClient.Results;

namespace ApiTest;

internal class UserOAuthConfiguration : Configuration
{
    private readonly OidcClient client;
    private LoginResult loginResult;
    private RefreshTokenResult refreshResult;
    private DateTimeOffset ExpiresOn;

    public UserOAuthConfiguration(string client_id,
        IEnumerable<string> scopes,
        string authority = "https://authentication.calcasa.nl/oauth2/v2.0",
        string redirectUri = "http://localhost",
        string basePath = "https://api.calcasa.nl") : base()
    {
        BasePath = basePath;
        var browser = new BrowserShim();
        var scope_list = scopes.ToList();
        //Scopes.Add("offline_access");
        if (!scopes.Contains(OidcConstants.StandardScopes.OpenId))
        {
            scope_list.Add(OidcConstants.StandardScopes.OpenId);
        }
        var OidcOptions = new OidcClientOptions
        {
            Authority = authority,
            ClientId = client_id,
            RedirectUri = redirectUri,
            Scope = string.Join(' ', scope_list),
            Browser = browser,
            LoadProfile = false,
        };
        client = new OidcClient(OidcOptions);
    }
    private string accessToken;

    public override string AccessToken
    {
        get
        {
            UpdateAccessToken().GetAwaiter().GetResult();
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
    private async Task UpdateAccessToken()
    {
        if (loginResult != null)
        {
            if (ExpiresOn > DateTimeOffset.UtcNow)
            {
                return;
            }
        }
        if (refreshResult != null)
        {
            if (!string.IsNullOrEmpty(refreshResult.RefreshToken))
            {
                refreshResult = await client.RefreshTokenAsync(refreshResult.RefreshToken);
            }
        }
        else if (loginResult != null)
        {
            if (!string.IsNullOrEmpty(refreshResult.RefreshToken))
            {
                refreshResult = await client.RefreshTokenAsync(refreshResult.RefreshToken);
            }
        }

        if (refreshResult?.IsError != false)
        {
            loginResult = await client.LoginAsync(new LoginRequest() { });

            if (loginResult.IsError)
            {
                Console.WriteLine(loginResult.Error, loginResult.ErrorDescription);
                Environment.Exit(1);
            }

            AccessToken = loginResult.AccessToken;
            ExpiresOn = loginResult.AccessTokenExpiration.ToUniversalTime();
        }
        else
        {
            AccessToken = refreshResult.AccessToken;
            ExpiresOn = refreshResult.AccessTokenExpiration.ToUniversalTime();
        }

    }
}