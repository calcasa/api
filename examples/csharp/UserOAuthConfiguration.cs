using Calcasa.Api.Client;
using Calcasa.Api.Api;
using Calcasa.Api.Model;
using System;
using System.Collections.Generic;
using System.Net.Http;
using IdentityModel.Client;
using System.Threading.Tasks;
using Microsoft.Identity.Client;
using Polly;
using static System.Formats.Asn1.AsnWriter;
using static System.Net.Mime.MediaTypeNames;
using System.Linq;

internal class UserOauthConfiguration : Configuration
{
    private readonly string ClientId;
    private readonly List<string> Scopes;
    private readonly string TenantId;
    private readonly string AuthDomain;
    private readonly string AuthPolicy;
    private readonly IPublicClientApplication AuthClient;
    private AuthenticationResult Token;
    private DateTimeOffset ExpiresOn;

    public UserOauthConfiguration(string client_id,
        IEnumerable<string> scopes,
        string tenantId = "c4a66657-fd72-488a-8f44-fd33fc77983f",
        string authDomain = "calcasalogin.b2clogin.com",
        string authPolicy = "b2c_1_signin1",
        string basePath = "https://api.calcasa.nl") : base()
    {
        ClientId = client_id;
        Scopes = scopes.Select(s => s.StartsWith("http") ? s : $"https://calcasalogin.onmicrosoft.com/public-api/{s}").ToList();
        //Scopes.Add("offline_access");
        TenantId = tenantId;
        AuthDomain = authDomain;
        AuthPolicy = authPolicy;
        BasePath = basePath;
        AuthClient = PublicClientApplicationBuilder.Create(ClientId)
               .WithB2CAuthority($"https://{AuthDomain}/tfp/{TenantId}/{AuthPolicy}")
               .WithRedirectUri("http://localhost")
               .Build();
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
        if (Token != null)
        {
            if (ExpiresOn > DateTimeOffset.UtcNow)
            {
                return;
            }
        }
        try
        {
            IEnumerable<IAccount> accounts = await AuthClient.GetAccountsAsync(AuthPolicy);
            IAccount account = accounts.FirstOrDefault();
            try
            {
                Token = await AuthClient.AcquireTokenSilent(Scopes, account)
                                              .ExecuteAsync();
            }
            catch (MsalUiRequiredException)
            {
                Token = await AuthClient.AcquireTokenInteractive(Scopes)
                                                .WithAccount(account)
                                                .ExecuteAsync();

            }
        }
        catch (Exception ex)
        {
            Token = null;
            throw new ApplicationException("Could not refresh token: [" + ex.GetType() + "] " + ex.Message);
        }
        if (Token != null)
        {
            ExpiresOn = Token.ExpiresOn.ToUniversalTime();
            AccessToken = Token.AccessToken;
        }
        else
        {
            throw new ApplicationException("Could not refresh token.");
        }

    }
}