//
//  VaporPathComponent+OpenAPI.swift
//  App
//
//  Created by Mathew Polzin on 12/8/19.
//

import Vapor
import VaporTypedRoutes
import OpenAPIKit

extension Vapor.PathComponent {
    internal func openAPIPathComponent() throws -> String {
        switch self {
        case .constant(let val):
            return val
        case .parameter(let val):
            return "{\(val)}"
        case .anything,
             .catchall:
            throw OpenAPIPathComponentError.unsupportedPathComponent(String(describing: self))
        }
    }

    internal func openAPIPathParameter(in route: Vapor.Route) -> OpenAPI.Parameter? {
        switch self {
        case .parameter(let name):
            let meta = route.userInfo["typed_parameter:\(name)"] as? TypedPathComponent.Meta

            return .init(
                name: name,
                context: .path,
                schema: (meta?.type as? OpenAPISchemaType.Type)?.openAPISchema ?? .string,
                description: meta?.description
            )
        default:
            return nil
        }
    }

    enum OpenAPIPathComponentError: Swift.Error {
        case unsupportedPathComponent(String)
    }
}
