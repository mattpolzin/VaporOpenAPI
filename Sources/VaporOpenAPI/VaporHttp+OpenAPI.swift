//
//  VaporHttp+OpenAPI.swift
//  App
//
//  Created by Mathew Polzin on 12/8/19.
//

import Vapor
import OpenAPIKit

extension HTTPMethod {
    /// The equivalent OpenAPI verb for the `HTTPMethod`.
    internal func openAPIVerb() throws -> OpenAPI.HttpMethod {
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

    /// Errors that can be thrown when attempting to convert from `HTTPMethod` to OpenAPI's equivalent.
    enum OpenAPIHTTPMethodError: Swift.Error {
        case unsupportedHttpMethod(String)
    }
}

extension HTTPMediaType {
    /// The equivalent OpenAPI `ContentType` for the `HTTPMediaType`.
    public var openAPIContentType: OpenAPI.ContentType? {
        return OpenAPI.ContentType(rawValue: "\(self.type)/\(self.subType)")
    }
}
