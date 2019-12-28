//
//  VaporPathComponent+OpenAPI.swift
//  App
//
//  Created by Mathew Polzin on 12/8/19.
//

import Vapor
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

    internal var openAPIPathParameter: OpenAPI.PathItem.Parameter? {
        switch self {
        case .parameter(let name):
            return .init(
                name: name,
                parameterLocation: .path,
                schema: .string
            )
        default:
            return nil
        }
    }

    enum OpenAPIPathComponentError: Swift.Error {
        case unsupportedPathComponent(String)
    }
}
