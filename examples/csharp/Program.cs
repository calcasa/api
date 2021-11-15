using Calcasa.Api.Client;
using Calcasa.Api.Api;
using Calcasa.Api.Model;
using System;
using System.Collections.Generic;
using System.Net.Http;
using IdentityModel.Client;
using System.Threading.Tasks;

namespace ApiTest
{
    class Program
    {
        static async Task Main(string[] args)
        {
            var conf = new OauthConfiguration(
                client_id: "<client_id>",
                client_secret: "<client_secret>"
                );

            var client = new ApiClient(conf.BasePath);

            var aa = new AdressenApi(client, client, conf); //Using this constructor is required so the class defined above is not lost by merging configurations in the constructor without the explicit clients.

            var adres = new Adres(postcode: "2611EB", huisnummer: 41);
            var adresinfo = await aa.SearchAdresAsync(adres);

            Console.WriteLine(adresinfo);
        }
    }
}
