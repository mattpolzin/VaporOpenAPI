//
//  VaporRoutes+OpenAPI.swift
//  AppAPIDocumentation
//
//  Created by Mathew Polzin on 10/20/19.
//

import Foundation
import OpenAPIKit
import Vapor

extension Vapor.Routes {
    /// Generates the equivalent OpenAPI `PathItem` map for the Vapor Routes.
    /// - Parameters:
    ///   - encoder: The JSON encoder to generate the OpenAPI path item map with.
    public func openAPIPathItems(using encoder: JSONEncoder) throws -> OpenAPI.PathItem.Map {
        let operations = try all
            .map { try $0.openAPIPathOperation(using: encoder) }

        let operationsByPath = OrderedDictionary(
            grouping: operations,
            by: { $0.path }
        )

        return operationsByPath.mapValues { operations in
            var pathItem = OpenAPI.PathItem()

            for item in operations {
                pathItem[item.verb] = item.operation
            }

            return pathItem
        }
    }
}
