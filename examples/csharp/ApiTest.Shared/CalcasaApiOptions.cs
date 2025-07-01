using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ApiTest.Shared;
public class CalcasaApiOptions
{
    public string ClientId { get; set; }
    public string ClientSecret { get; set; }
    public string TokenUrl { get; set; } = "https://authentication.calcasa.nl/oauth2/v2.0/token";
}
