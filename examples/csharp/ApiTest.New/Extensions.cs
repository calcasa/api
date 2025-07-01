using System;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using ApiTest.Shared;
using Calcasa.Api.Api;
using Calcasa.Api.Client;
using Calcasa.Api.Extensions;
using Calcasa.Api.Model;
using Duende.IdentityModel.OidcClient;
using Microsoft.AspNetCore.JsonPatch;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace ApiTest.New;
internal static class Extensions
{
    public static void HandleErrorResponse<TResponse>(this TResponse response)
        where TResponse : IApiResponse
    {
        if (response is IUnauthorized<Calcasa.Api.Model.UnauthorizedProblemDetails?> UnauthorizedResponse)
        {
            if (UnauthorizedResponse.TryUnauthorized(out var result))
            {
                throw new ApiException($"Unauthorized: {result.Detail}", response.StatusCode, response.RawContent);
            }
        }

        if (response is IForbidden<Calcasa.Api.Model.PermissionsDeniedProblemDetails?> ForbiddenResponse)
        {
            if (ForbiddenResponse.TryForbidden(out var result))
            {
                throw new ApiException($"Forbidden: {result.Detail} {result.RequiredPermission}", response.StatusCode, response.RawContent);
            }
        }

        if (response is INotFound<Calcasa.Api.Model.NotFoundProblemDetails?> NotFoundResponse)
        {
            if (NotFoundResponse.TryNotFound(out var result))
            {
                throw new ApiException($"Forbidden: {result.Detail} {result.Entity}", response.StatusCode, response.RawContent);
            }
        }

        if (response is IDefault<Microsoft.AspNetCore.Mvc.ProblemDetails?> DefaultResponse)
        {
            if (DefaultResponse.TryDefault(out var result))
            {
                throw new ApiException($"{result.Title}: {result.Detail}", response.StatusCode, response.RawContent);
            }
        }


        throw new ApiException($"Unkown error: {response}", response.StatusCode, response.RawContent);
    }
}
