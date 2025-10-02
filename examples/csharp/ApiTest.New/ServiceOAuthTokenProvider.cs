using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using ApiTest.Shared;
using Calcasa.Api;
using Calcasa.Api.Client;
using Duende.IdentityModel.Client;
using Microsoft.Extensions.Options;

namespace ApiTest.New;

public class ServiceOAuthTokenProvider : TokenProvider<OAuthToken>
{
    private readonly string ClientId;
    private readonly string ClientSecret;
    private readonly string TokenUrl;
    private readonly HttpClient AuthClient;
    private ConcurrentDictionary<string, (TokenResponse Token, DateTime ExpiresOn)> Tokens;

    public ServiceOAuthTokenProvider(IOptions<CalcasaApiOptions> options)
    {
        Tokens = [];
        ClientId = options.Value.ClientId;
        ClientSecret = options.Value.ClientSecret;
        TokenUrl = options.Value.TokenUrl;
        AuthClient = new HttpClient();
    }

    public override ValueTask<OAuthToken> GetAsync(string header = "", CancellationToken cancellation = default)
    {
        var data = Tokens.GetValueOrDefault(header);

        if (data.Token != null)
        {
            if (!data.Token.IsError || data.ExpiresOn > DateTime.UtcNow)
            {
                return ValueTask.FromResult(new OAuthToken(data.Token.AccessToken));
            }
        }

        var request = new ClientCredentialsTokenRequest
        {
            Address = TokenUrl,
            ClientId = ClientId,
            ClientSecret = ClientSecret,
            ClientCredentialStyle = ClientCredentialStyle.AuthorizationHeader, // Recommended as opposed to secrets in body.
        };

        data.Token = AuthClient.RequestClientCredentialsTokenAsync(request).Result;

        if (data.Token.IsError)
        {
            throw new ApplicationException("Could not refresh token: [" + data.Token.ErrorType + "] " + data.Token.Error + "; " + data.Token.ErrorDescription);
        }
        else
        {
            data.ExpiresOn = DateTime.UtcNow.AddSeconds(data.Token.ExpiresIn);
            Tokens.AddOrUpdate(header, (h) => data, (h, oldData) => data);

            return ValueTask.FromResult(new OAuthToken(data.Token.AccessToken));
        }
    }
}
