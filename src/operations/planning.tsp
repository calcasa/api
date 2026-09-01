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
    @useAuth(oauth<["api:planning:read"]>)
    @route("/opnames")
    @get
    @summary("Get the list of opnames.")
    @operationId("GetOpnames")
    op GetOpnames(@query(#{ explode: true }) include_planned?: boolean = false):
        | Opname[]
        | UnauthorizedProblemDetails
        | ProblemDetails;

    @useAuth(oauth<["api:planning:read"]>)
    @route("/opnemers")
    @get
    @summary("Get the list of opnemers.")
    @operationId("GetOpnemers")
    op GetOpnemers():
        | Opnemer[]
        | UnauthorizedProblemDetails
        | ProblemDetails;

    @route("/opnames/{opnameId}")
    @post
    @useAuth(oauth<["api:planning:write"]>)
    @summary("Assign opnemer to opname.")
    @operationId("AssignOpnemer")
    op AssignOpnemer(@format("uuid") opnameId: string, @bodyRoot body: PlanningInfo):
        | PlanningInfo
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;

    @route("/opnames/{opnameId}")
    @delete
    @summary("Delete the planning for an opname.")
    @useAuth(oauth<["api:planning:write"]>)
    @operationId("DeletePlanningForOpname")
    op DeletePlanningForOpname(@format("uuid") opnameId: string):
        | NoContentResponse
        | NotFoundProblemDetails
        | UnauthorizedProblemDetails
        | ProblemDetails;
}
