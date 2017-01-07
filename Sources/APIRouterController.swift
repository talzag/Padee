//
//  APIRouter.swift
//  PadeeServer
//
//  Created by Daniel Strokis on 1/7/17.
//
//

import Kitura

typealias RouteHandler = () -> Void

class APIRouterController {
    let router = Router()
    
    public init() {
        router.get("/", handler: getAPICall)
    }
    
    func getAPICall(request: RouterRequest, response: RouterResponse, next: @escaping RouteHandler) throws {
        response.status(.OK).send("Response from Padee server API router")
        next()
    }
}
