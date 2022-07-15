using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

using IdentityModel.OidcClient.Browser;

namespace ApiTest;
internal class BrowserShim : IBrowser
{
    public async Task<BrowserResult> InvokeAsync(BrowserOptions options, CancellationToken cancellationToken = default(CancellationToken))
    {
        // You can change this to start a browser and some http listener for your platform (desktop or web).
        // See https://identitymodel.readthedocs.io/en/latest/ for more details.
        Console.WriteLine($"Please open {options.StartUrl} in your browser to complete authentication.");
        Console.WriteLine($"And paste the final redriect URI in here:");

        var result = Console.ReadLine();

        if (string.IsNullOrWhiteSpace(result))
        {
            return new BrowserResult { ResultType = BrowserResultType.UnknownError, Error = "Empty response." };
        }

        return new BrowserResult { Response = result, ResultType = BrowserResultType.Success };

    }
}
