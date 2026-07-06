using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using ApiTest.Shared;
using Calcasa.Api.Api;
using Calcasa.Api.Client;
using Calcasa.Api.Extensions;
using Calcasa.Api.Model;
using dotenv.net;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MimeKit;
using FileInfo = Calcasa.Api.Model.FileInfo;

DotEnv.Load(new DotEnvOptions(probeForEnv: true, probeLevelsToSearch: 5)); // 5 levels so when run in VS it works.

if (Environment.GetEnvironmentVariable("CALCASA_CLIENT_ID") == null || Environment.GetEnvironmentVariable("CALCASA_CLIENT_SECRET") == null)
{
    throw new ArgumentException("Set the CALCASA_CLIENT_ID and CALCASA_CLIENT_SECRET enviroment variables or set them in the .env file.");
}

if (Environment.GetEnvironmentVariable("CALCASA_TEST_FILE_SET_PATH") == null)
{
    throw new ArgumentException("Set the CALCASA_TEST_FILE_SET_PATH environment variable or set it in the .env file.");
}

var host = Host.CreateDefaultBuilder(args).ConfigureApi(static (context, services, options) =>
{
    options.AddApiHttpClients(c => c.BaseAddress = new Uri("https://api.staging.calcasa.nl/api/v1"));
    services.Configure<CalcasaApiOptions>(o =>
    {
        o.ClientId = Environment.GetEnvironmentVariable("CALCASA_CLIENT_ID")!;
        o.ClientSecret = Environment.GetEnvironmentVariable("CALCASA_CLIENT_SECRET")!;
        o.TokenUrl = "https://authentication.01.staging.calcasa.nl/oauth2/v2.0/token";
    });
    options.UseProvider<ServiceOAuthTokenProvider, OAuthToken>();
}).Build();

var logger = host.Services.GetRequiredService<ILogger<Program>>();
var fs = host.Services.GetRequiredService<IFileSetsApi>();

var file_set_directory = Environment.GetEnvironmentVariable("CALCASA_TEST_FILE_SET_PATH")!;

if (!Directory.Exists(file_set_directory))
{
    throw new DirectoryNotFoundException($"Directory {file_set_directory} not found.");
}

var files = new List<FileInfo>();
int idx = 0;

foreach (var file in Directory.GetFiles(file_set_directory, "*.*", SearchOption.AllDirectories))
{
    var content = File.ReadAllBytes(file);
    files.Add(new FileInfo(
        index: idx,
        name: Path.GetFileName(file),
        contentHash: Convert.ToHexString(SHA256.HashData(content)),
        size: content.LongLength,
        contentType: MimeTypes.GetMimeType(file)
    ));
}

var create_request = new CreateInboundFileSetRequest(
    type: "test-file-set",
    revision: 0,
    period: DateOnly.FromDateTime(DateTime.UtcNow),
    files: files
    );

var ifsResponse = await fs.CreateInboundFileSetAsync(create_request);

if (!ifsResponse.TryOk(out var ifs)) ifsResponse.HandleErrorResponse();

Console.WriteLine(ifs);
