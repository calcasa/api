using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using ApiTest.Shared;
using Calcasa.Api.Api;
using Calcasa.Api.Client;
using Calcasa.Api.Extensions;
using Calcasa.Api.Model;
using Microsoft.AspNetCore.JsonPatch.Operations;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace ApiTest.New;


internal class Program
{
    public static async Task Main(string[] args)
    {
        var host = Host.CreateDefaultBuilder(args).ConfigureApi(static (context, services, options) =>
        {
            options.AddApiHttpClients(c => c.BaseAddress = new Uri("https://api.staging.calcasa.nl/api/v1"));
            services.Configure<CalcasaApiOptions>(o =>
            {
                o.ClientId = "<client_id>";
                o.ClientSecret = "<client_secret>";
                o.TokenUrl = "https://authentication.01.staging.calcasa.nl/oauth2/v2.0/token";
            });
            options.UseProvider<ServiceOAuthTokenProvider, OAuthToken>();
        }).Build();

        var logger = host.Services.GetRequiredService<ILogger<Program>>();
        var aa = host.Services.GetRequiredService<IAdressenApi>();
        var ca = host.Services.GetRequiredService<IConfiguratieApi>();
        var wa = host.Services.GetRequiredService<IWaarderingenApi>();
        var ra = host.Services.GetRequiredService<IRapportenApi>();
        var fa = host.Services.GetRequiredService<IFacturenApi>();
        var pa = host.Services.GetRequiredService<IFotosApi>();

        /* --------------- *
         * Adres endpoints *
         * --------------- */

        var adres = new Adres(postcode: "2547KE", huisnummer: 259); // Create Adres instance to be checked.
        var adresInfoResponse = await aa.SearchAdresAsync(adres); // Check the adres against the API.

        if (!adresInfoResponse.TryOk(out var adresInfo)) adresInfoResponse.HandleErrorResponse();

        Console.WriteLine(adresInfo);

        var officeAddressInfoResponse = await aa.GetAdresAsync(307200000435341); // Get address information based on the BAG Nummeraanduiding ID.

        if (!officeAddressInfoResponse.TryOk(out var officeAddressInfo)) officeAddressInfoResponse.HandleErrorResponse();

        Console.WriteLine(officeAddressInfo);

        /* ----------------------- *
         * Configuration endpoints *
         * ----------------------- */

        // Please use the correct version string and make sure the URL is publicly resolvable and reachable by arbitrary IPs.
        // This will result in requests going to https://test.calcasa.nl/callback/waardering for the waardering callback.
        // You can also use query parameters like "https://test.calcasa.nl/callback.aspx?callbackType=" which would result in the final URl being: https://test.calcasa.nl/callback.aspx?callbackType=waardering for the waardering callback.
        var callback = new Callback("v1", "https://test.calcasa.nl/callback/");
        var configsResponse = await ca.UpdateCallbacksAsync(callback);

        if (!configsResponse.TryOk(out var configs)) officeAddressInfoResponse.HandleErrorResponse();

        foreach (var config in configs)
        {
            Console.WriteLine(config);
        }

        //This is a test so we will reset it to an empty value to disable the webhook. If you are not returning HTTP 200, please disable the unused callback to reduce request spam from our infrastructure to the endpoint configured.
        var callbackReset = new Callback("v1", null);
        var configsResetResponse = await ca.UpdateCallbacksAsync(callbackReset);

        if (!configsResetResponse.TryOk(out var configsReset)) configsResetResponse.HandleErrorResponse();

        foreach (var config in configsReset)
        {
            Console.WriteLine(config);
        }

        /* ---------------------- *
         * Waarderingen endpoints *
         * ---------------------- */

        // If you need to create a new valuation this is a multi step process.

        var waarderingInput = new WaarderingInputParameters(
            productType: ProductType.DesktopTaxatie,
            hypotheekwaarde: 205000,
            aanvraagdoel: Aanvraagdoel.AankoopNieuweWoning,
            klantwaarde: 305000,
            klantwaardeType: KlantwaardeType.Koopsom,
            isBestaandeWoning: true,
            bagNummeraanduidingId: adresInfo.BagNummeraanduidingId,
            isNhg: false,
            isErfpacht: false
            );

        var waarderingOutputResponse = await wa.CreateWaarderingAsync(waarderingInput);

        if (!waarderingOutputResponse.TryOk(out var waarderingOutput)) waarderingOutputResponse.HandleErrorResponse();

        Console.WriteLine(waarderingOutput);

        //Save the Id for future reference.
        var id = waarderingOutput.Id;

        // Eventually check if the address is correct in the output and then confirm the valuation. This can mean presenting the information to the user and asking them to confirm for example.

        // Now that we want to confirm the valuation we are going to patch the status to open.

        List<Operation> jsonPatch = [
            new Operation(OperationType.Replace.ToString(), "/status", string.Empty, "open")
        ];

        var waarderingOutputAfterPatchResponse = await wa.PatchWaarderingenAsync(id, jsonPatch);

        if (!waarderingOutputAfterPatchResponse.TryOk(out var waarderingOutputAfterPatch)) waarderingOutputAfterPatchResponse.HandleErrorResponse();

        // Now is a good time to persist the Id and the other information to a database.

        // Some time later. (Note this sleep simulation only works for test requests, in the real world valuations might be much slower depending on the ProductType.
        Console.WriteLine("Waiting 10 seconds...");
        await Task.Delay(10_000);

        // The webhook will fire when the status has changed succesfully.
        // Lets simulate a Webhook payload and process it.

        var webhookPayload = new WaarderingWebhookPayload(
            callbackName: "waardering",
            eventId: Guid.NewGuid(), // This is the Id of the actual upstream event, this stays the same across retries. (Save this if your handling of this webhook is not idempotent)
            waarderingId: id, // This is the valuation id.
            oldStatus: WaarderingStatus.Open,
            newStatus: WaarderingStatus.Voltooid,
            timestamp: DateTime.UtcNow, // This is the timestamp of the original event.
            isTest: true);

        // Here follow some example procesing code for example to download the photo, photo and/or photos.

        if (webhookPayload.NewStatus == WaarderingStatus.Voltooid)
        {
            // The valuation is complete and will now have full output, lets request the valuation
            var completeWaarderingResponse = await wa.GetWaarderingAsync(webhookPayload.WaarderingId.Value);

            if (!completeWaarderingResponse.TryOk(out var completeWaardering)) completeWaarderingResponse.HandleErrorResponse();

            await HandleAndPersistValuation(completeWaardering, ra, fa, pa);
        }

        Console.WriteLine($"Done with valuation {id}.");


        //If instead you want to find the waarderingen objects and you don't have the Ids this endpoint lets your search for them. The ProductType and BAG Id are required, we can reuse the results from our previous SearchAdres call.
        var searchParameters = new WaarderingZoekParameters(productType: ProductType.ModelwaardeDesktopTaxatie, bagNummeraanduidingId: adresInfo.BagNummeraanduidingId);

        var waarderingenResponse = await wa.SearchWaarderingenAsync(searchParameters);

        if (!waarderingenResponse.TryOk(out var waarderingen)) waarderingenResponse.HandleErrorResponse();

        foreach (var waardering in waarderingen)
        {
            // This would give you the oppurtunity to grab the lastest one for example or filter further to pick the one you need.
            Console.WriteLine($"Found: {waardering.Id}");
        }
        if (waarderingen.Any())
        {
            // This is how you get the latest valuation to for example download the Report.
            var lastValuationForAddress = waarderingen.OrderByDescending(w => w.Aangemaakt).First();

            Console.WriteLine($"Last valuation: {lastValuationForAddress.Id}");
            await HandleAndPersistValuation(lastValuationForAddress, ra, fa, pa);
        }

    }

    private static async Task HandleAndPersistValuation(Waardering completeWaardering, IRapportenApi ra, IFacturenApi fa, IFotosApi pa)
    {
        // For example inspect the Model output and persist it locally. (Remember that every field can be null).
        var marktwaarde = completeWaardering.Model?.Marktwaarde;
        Console.WriteLine($"Marktwaarde: {marktwaarde}");

        //For select product types the result of the manual valuation is also available.
        var taxatiestatus = completeWaardering.Taxatie?.Status;
        Console.WriteLine($"Taxatiestatus: {taxatiestatus}");

        // Do we have a photo?
        if (completeWaardering.Rapport != null && completeWaardering.Rapport.Id != Guid.Empty)
        {
            var reportResponse = await ra.GetRapportAsync(completeWaardering.Rapport.Id);

            if (!reportResponse.TryOk(out var reportStream)) reportResponse.HandleErrorResponse();

            var fileName = "calcasa-report.pdf";

            if (reportResponse.ContentHeaders.ContentDisposition != null)
            {
                fileName = $"calcasa-report-{reportResponse.ContentHeaders.ContentDisposition.FileName}";
            }

            Console.WriteLine($"Saving {fileName}");
            //Process the PDF file, for example save it to a file.
            using (var fileStream = File.Create(fileName))
            {
                await reportStream.CopyToAsync(fileStream);
            }
            // Reset the Content stream to the beginning.
            reportStream.Seek(0, SeekOrigin.Begin);

            // Or for example pass it through to the next service or document database as a byteArray.
            using (var memoryStream = new MemoryStream())
            {
                await reportStream.CopyToAsync(memoryStream);
                await memoryStream.FlushAsync();
                var byteArray = memoryStream.ToArray();
                // Then post/send byteArray somewhere else.
            }

        }

        // Do we have an photo?
        if (completeWaardering.Factuur != null && completeWaardering.Factuur.Id != Guid.Empty)
        {
            var invoiceResponse = await fa.GetFactuurAsync(completeWaardering.Factuur.Id);

            if (!invoiceResponse.TryOk(out var invoiceStream)) invoiceResponse.HandleErrorResponse(); // Don't use TryOk, generated code does not handle files gracefully.

            var fileName = "calcasa-invoice.pdf";

            if (invoiceResponse.ContentHeaders.ContentDisposition != null)
            {
                fileName = $"calcasa-invoice-{invoiceResponse.ContentHeaders.ContentDisposition.FileName}";
            }
            Console.WriteLine($"Saving {fileName}");
            //Process the PDF file, for example save it to a file.
            using (var fileStream = File.Create(fileName))
            {
                await invoiceStream.CopyToAsync(fileStream);
            }

        }


        // Do we have photos?
        if (completeWaardering.Fotos != null && completeWaardering.Fotos.Any())
        {
            foreach (var foto in completeWaardering.Fotos)
            {
                var photoResponse = await pa.GetFotoAsync(foto.Id.Value);

                if (!photoResponse.TryOk(out var photoStream)) photoResponse.HandleErrorResponse(); // Don't use TryOk, generated code does not handle files gracefully.

                var fileName = "calcasa-photo.jpeg";

                if (photoResponse.ContentHeaders.ContentDisposition != null)
                {
                    fileName = $"calcasa-photo-{photoResponse.ContentHeaders.ContentDisposition.FileName}";
                }

                Console.WriteLine($"Saving {fileName}");
                //Process the PDF file, for example save it to a file.
                using (var fileStream = File.Create(fileName))
                {
                    await photoStream.CopyToAsync(fileStream);
                }

            }

        }
    }


}
