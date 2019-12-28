//
//  VaporHttp+OpenAPI.swift
//  App
//
//  Created by Mathew Polzin on 12/8/19.
//

import Vapor
import OpenAPIKit

extension HTTPMethod {
    internal func openAPIVerb() throws -> OpenAPI.HttpVerb {
        switch self {
        case .GET:
            return .get
        case .PUT:
            return .put
        case .POST:
            return .post
        case .DELETE:
            return .delete
        case .OPTIONS:
            return .options
        case .HEAD:
            return .head
        case .PATCH:
            return .patch
        case .TRACE:
            return .trace
        default:
            throw OpenAPIHTTPMethodError.unsupportedHttpMethod(String(describing: self))
        }
    }

    enum OpenAPIHTTPMethodError: Swift.Error {
        case unsupportedHttpMethod(String)
    }
}

extension HTTPMediaType {
    public var openAPIContentType: OpenAPI.ContentType? {
        return OpenAPI.ContentType(rawValue: "\(self.type)/\(self.subType)")
    }
}
