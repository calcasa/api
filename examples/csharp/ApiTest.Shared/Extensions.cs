using Calcasa.Api.Client;

namespace ApiTest.Shared;

public static class Extensions
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
                throw new ApiException($"Not Found: {result.Detail} {result.Entity}", response.StatusCode, response.RawContent);
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
