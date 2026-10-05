import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "../models/planning.tsp";
//import "../errors/file_sets.tsp";

using Http;
using OpenAPI;

namespace CalcasaPublicApi;

@tag("Planning")
@route("/planning")
namespace Planning {
    /**
     * Geeft de lijst met opnames terug. Gebruik include_planned om ook geplande opnames op te nemen.
     */
    @useAuth(oauth<["api:planning:read"]>)
    @route("/opnames")
    @get
    @summary("List opnames.")
    @operationId("GetOpnames")
    op GetOpnames(@query(#{ explode: true }) include_planned?: boolean = false):
        | Opname[]
        | UnauthorizedProblemDetails
        | ProblemDetails;

    /**
     * Geeft de lijst met opnemers terug.
     */
    @useAuth(oauth<["api:planning:read"]>)
    @route("/opnemers")
    @get
    @summary("List opnemers.")
    @operationId("GetOpnemers")
    op GetOpnemers():
        | Opnemer[]
        | UnauthorizedProblemDetails
        | ProblemDetails;

    /**
     * Wijst een opnemer toe aan een opname.
     */
    @route("/opnames/{opnameId}")
    @post
    @useAuth(oauth<["api:planning:write"]>)
    @summary("Assign an opnemer.")
    @operationId("AssignOpnemer")
    op AssignOpnemer(@format("uuid") opnameId: string, @bodyRoot body: PlanningInfo):
        | PlanningInfo
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    /**
     * Verwijdert de planning voor een opname.
     */
    @route("/opnames/{opnameId}")
    @delete
    @summary("Delete an opname planning.")
    @useAuth(oauth<["api:planning:write"]>)
    @operationId("DeletePlanningForOpname")
    op DeletePlanningForOpname(@format("uuid") opnameId: string):
        | NoContentResponse
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;
}
