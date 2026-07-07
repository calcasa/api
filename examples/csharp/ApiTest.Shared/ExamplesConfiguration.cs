using Calcasa.Api;
using Calcasa.Api.Client;
using Calcasa.Api.Extensions;
using dotenv.net;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace ApiTest.Shared;

public static class ExamplesConfiguration
{
    private const int ProbeLevelsToSearch = 5;
    private static bool _isEnvironmentLoaded;
    private static readonly Lock EnvironmentLoadLock = new();

    public static IHost CreateApiHost(string[] args)
    {
        EnsureEnvironmentLoaded();

        var clientId = GetRequiredEnvironmentVariable("CALCASA_CLIENT_ID");
        var clientSecret = GetRequiredEnvironmentVariable("CALCASA_CLIENT_SECRET");
        var tokenEndpoint = GetRequiredEnvironmentVariable("CALCASA_TOKEN_ENDPOINT");
        var apiBaseUrl = GetRequiredEnvironmentVariable("CALCASA_API_BASE_URL");

        return Host.CreateDefaultBuilder(args).ConfigureApi((context, services, options) =>
        {
            options.AddApiHttpClients(c => c.BaseAddress = new Uri(apiBaseUrl));
            services.Configure<CalcasaApiOptions>(o =>
            {
                o.ClientId = clientId;
                o.ClientSecret = clientSecret;
                o.TokenUrl = tokenEndpoint;
            });

            options.UseProvider<ServiceOAuthTokenProvider, OAuthToken>();
        }).Build();
    }

    public static string GetRequiredEnvironmentVariable(string name)
    {
        EnsureEnvironmentLoaded();

        var value = Environment.GetEnvironmentVariable(name);
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException($"Set the {name} environment variable or set it in the .env file.");
        }

        return value;
    }

    private static void EnsureEnvironmentLoaded()
    {
        if (_isEnvironmentLoaded)
        {
            return;
        }

        lock (EnvironmentLoadLock)
        {
            if (_isEnvironmentLoaded)
            {
                return;
            }

            DotEnv.Load(new DotEnvOptions(probeForEnv: true, probeLevelsToSearch: ProbeLevelsToSearch));
            _isEnvironmentLoaded = true;
        }
    }
}
