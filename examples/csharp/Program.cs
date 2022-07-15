using Calcasa.Api.Client;
using Calcasa.Api.Api;
using Calcasa.Api.Model;
using System;
using System.Collections.Generic;
using System.Net.Http;
using IdentityModel.Client;
using System.Threading.Tasks;
using System.Threading;
using System.IO;
using System.Linq;

namespace ApiTest
{
    class Program
    {
        static async Task Main(string[] args)
        {
            // Change this to change between different authorization schemes.
            var userAuthentication = false;

            Configuration conf;
            if (!userAuthentication)
            {
                conf = new ServiceOAuthConfiguration(
                    client_id: "<client_id>", // Calcasa Client Id
                    client_secret: "<client_secret>" // Client Secret
                );
            }
            else
            {
                conf = new UserOAuthConfiguration(
                    client_id: "<client_id>", // Client Id
                    scopes: new string[] { "openid", "offline_access" } // Scopes (when these are the only ones given it will be filled with all scopes the user has access to). The `openid` scope is mandatory from the standard.
                    );
            }

            // Set the User Agent of your application
            conf.UserAgent = "CSharp Application Name/0.0.1";

            // HttpClientHandler and HttpClient should be reused.

            var httpClientHandler = new HttpClientHandler();
            var httpClient = new HttpClient(httpClientHandler);

            // Using this constructor is required so the HttpClient is properly reused.
            var aa = new AdressenApi(httpClient, conf, httpClientHandler);
            var ca = new ConfiguratieApi(httpClient, conf, httpClientHandler);
            var wa = new WaarderingenApi(httpClient, conf, httpClientHandler);
            var ra = new RapportenApi(httpClient, conf, httpClientHandler);
            var fa = new FacturenApi(httpClient, conf, httpClientHandler);
            var pa = new FotosApi(httpClient, conf, httpClientHandler);

            /* --------------- *
             * Adres endpoints *
             * --------------- */

            var adres = new Adres(postcode: "3823JC", huisnummer: 94); // Create Adres instance to be checked.            
            var adresinfo = await aa.SearchAdresAsync(adres); // Check the adres against the API.

            Console.WriteLine(adresinfo);

            var officeAddressInfo = await aa.GetAdresAsync(307200000435341); // Get address information based on the BAG Nummeraanduiding ID.

            Console.WriteLine(officeAddressInfo);

            /* ----------------------- *
             * Configuration endpoints *
             * ----------------------- */

            // Please use the correct version string and make sure the URL is publicly resolvable and reachable by arbitrary IPs.
            // This will result in requests going to https://test.calcasa.nl/callback/waardering for the waardering callback.
            // You can also use query parameters like "https://test.calcasa.nl/callback.aspx?callbackType=" which would result in the final URl being: https://test.calcasa.nl/callback.aspx?callbackType=waardering for the waardering callback.
            var callback = new Callback("v1", "https://test.calcasa.nl/callback/"); 
            var configs = await ca.UpdateCallbacksAsync(callback);

            foreach (var config in configs)
            {
                Console.WriteLine(config);
            }

            //This is a test so we will reset it to an empty value to disable the webhook. If you are not returning HTTP 200, please disable the unused callback to reduce request spam from our infrastructure to the endpoint configured.
            var callbackReset = new Callback("v1", null);
            var configsReset = await ca.UpdateCallbacksAsync(callbackReset);

            foreach (var config in configsReset)
            {
                Console.WriteLine(config);
            }

            /* ---------------------- *
             * Waarderingen endpoints *
             * ---------------------- */

            // If you need to create a new valuation this is a multi step process.

            var waarderingInput = new WaarderingInputParameters(
                productType: ProductType.ModelwaardeDesktopTaxatie,
                hypotheekwaarde: 350000,
                aanvraagdoel: Aanvraagdoel.AankoopNieuweWoning,
                klantwaarde: 450000,
                klantwaardeType: KlantwaardeType.Koopsom,
                isBestaandeWoning: true,
                bagNummeraanduidingId: adresinfo.BagNummeraanduidingId,
                isNhg: false,
                isErfpacht: false
                );

            var waarderingOutput = await wa.CreateWaarderingAsync(waarderingInput);

            Console.WriteLine(waarderingOutput);

            //Save the Id for future reference.
            var id = waarderingOutput.Id;

            // Eventually check if the address is correct in the output and then confirm the valuation. This can mean presenting the information to the user and asking them to confirm for example.

            // Now that we want to confirm the valuation we are going to patch the status to open.

            var jsonPatch = new JsonPatchDocument() // JsonPatchDocument is a wrapper around Collection<Operation>
            {
                new Operation()
                {
                    Path = "/status",
                    Op = OperationType.Replace,
                    Value = "open"
                }
            };

            var waarderingOutputAfterPatch = await wa.PatchWaarderingenAsync(id, jsonPatch);

            // Now is a good time to persist the Id and the other information to a database.

            // Some time later. (Note this sleep simulation only works for test requests, in the real world valuations might be much slower depending on the ProductType.
            Console.WriteLine("Waiting 10 seconds...");
            await Task.Delay(10_000);

            // The webhook will fire when the status has changed succesfully.
            // Lets simulate a Webhook payload and process it.

            var webhookPayload = new WaarderingWebhookPayload(
                eventId: Guid.NewGuid(), // This is the Id of the actual upstream event, this stays the same across retries. (Save this if your handling of this webhook is not idempotent)
                waarderingId: id, // This is the valuation id.
                oldStatus: WaarderingStatus.Open,
                newStatus: WaarderingStatus.Voltooid,
                timestamp: DateTime.UtcNow, // This is the timestamp of the original event.
                isTest: true);

            // Here follow some example procesing code for example to download the report, invoice and/or photos.

            if(webhookPayload.NewStatus == WaarderingStatus.Voltooid)
            {
                // The valuation is complete and will now have full output, lets request the valuation
                var completeWaardering = await wa.GetWaarderingAsync(webhookPayload.WaarderingId);
                await HandleAndPersistValuation(completeWaardering, ra,fa,pa);
            }

            Console.WriteLine($"Done with valuation {id}.");


            //If instead you want to find the waarderingen objects and you don't have the Ids this endpoint lets your search for them. The ProductType and BAG Id are required, we can reuse the results from our previous SearchAdres call.
            var searchParameters = new WaarderingZoekParameters(productType: ProductType.ModelwaardeDesktopTaxatie, bagNummeraanduidingId: adresinfo.BagNummeraanduidingId);
            var waarderingen = await wa.SearchWaarderingenAsync(searchParameters);


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

        static async Task HandleAndPersistValuation(Waardering completeWaardering, RapportenApi ra, FacturenApi fa, FotosApi pa) {
            // For example inspect the Model output and persist it locally. (Remember that every field can be null).
            var marktwaarde = completeWaardering.Model?.Marktwaarde;
            Console.WriteLine($"Marktwaarde: {marktwaarde}");

            //For select product types the result of the manual valuation is also available.
            var taxatiestatus = completeWaardering.Taxatie?.Status;
            Console.WriteLine($"Taxatiestatus: {taxatiestatus}");

            // Do we have a report?
            if (completeWaardering.Rapport != null && completeWaardering.Rapport.Id != Guid.Empty)
            {
                var report = await ra.GetRapportAsync(completeWaardering.Rapport.Id);

                if (report.ContentType == "application/pdf")
                {
                    Console.WriteLine($"Saving calcasa-report-{report.Name}");
                    //Process the PDF file, for example save it to a file.
                    using (var fileStream = File.Create($"calcasa-report-{report.Name}"))
                    {
                        await report.Content.CopyToAsync(fileStream);
                    }
                    // Reset the Content stream to the beginning.
                    report.Content.Seek(0, SeekOrigin.Begin);

                    // Or for example pass it through to the next service or document database as a byteArray.
                    using (var memoryStream = new MemoryStream())
                    {
                        await report.Content.CopyToAsync(memoryStream);
                        await memoryStream.FlushAsync();
                        var byteArray = memoryStream.ToArray();
                        // Then post/send byteArray somewhere else.
                    }
                }
            }

            // Do we have an invoice?
            if (completeWaardering.Factuur != null && completeWaardering.Factuur.Id != Guid.Empty)
            {
                var invoice = await fa.GetFactuurAsync(completeWaardering.Factuur.Id);

                if (invoice.ContentType == "application/pdf")
                {
                    Console.WriteLine($"Saving calcasa-invoice-{invoice.Name}");
                    //Process the PDF file, for example save it to a file.
                    using (var fileStream = File.Create($"calcasa-invoice-{invoice.Name}"))
                    {
                        await invoice.Content.CopyToAsync(fileStream);
                    }
                }

            }


            // Do we have photos?
            if (completeWaardering.Fotos != null && completeWaardering.Fotos.Any())
            {
                foreach (var foto in completeWaardering.Fotos)
                {
                    var photo = await pa.GetFotoAsync(foto.Id);

                    if (photo.ContentType.StartsWith("image/"))
                    {
                        Console.WriteLine($"Saving calcasa-photo-{photo.Name}");
                        //Process the PDF file, for example save it to a file.
                        using (var fileStream = File.Create($"calcasa-photo-{photo.Name}"))
                        {
                            await photo.Content.CopyToAsync(fileStream);
                        }
                    }
                }

            }
        }
    }
}
