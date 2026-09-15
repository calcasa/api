import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";
import "@typespec/versioning";

import "../models.tsp";

using TypeSpec.Versioning;
using Http;
using OpenAPI;

namespace CalcasaPublicApi;

model Opnemer {
    @key @format("uuid") id: string;

    email: string;

    name: string;
}

model PlanningInfo {
    @key @format("uuid") opnemer_id: string;

    @example(plainDate.fromISO("2021-04-28"))
    datum: plainDate;
}

model Point {
    latitude: float64;
    longitude: float64;
}

model Opname {
    @key @format("uuid") id: string;

    adres: Adres;

    coordinaten: Point;

    @example(utcDateTime.fromISO("2021-04-28T12:34:45Z"))
    @encode(DateTimeKnownEncoding.rfc3339)
    deadline: utcDateTime;

    batchCode: string;

    product: ProductType;

    woningType: WoningType;

    planning?: PlanningInfo | null;
}
