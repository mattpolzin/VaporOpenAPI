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
    public func openAPIPathItems(using encoder: JSONEncoder) throws -> OpenAPI.PathItem.Map {
        let operations = try all
            .map { try $0.openAPIPathOperation(using: encoder) }

        let operationsByPath = Dictionary(
            grouping: operations,
            by: { $0.path }
        )

        return operationsByPath.mapValues { operations in
            var get: OpenAPI.PathItem.Operation? = nil
            var put: OpenAPI.PathItem.Operation? = nil
            var post: OpenAPI.PathItem.Operation? = nil
            var delete: OpenAPI.PathItem.Operation? = nil
            var options: OpenAPI.PathItem.Operation? = nil
            var head: OpenAPI.PathItem.Operation? = nil
            var patch: OpenAPI.PathItem.Operation? = nil
            var trace: OpenAPI.PathItem.Operation? = nil

            for item in operations {
                switch item.verb {
                case .get:
                    get = item.operation
                case .put:
                    put = item.operation
                case .post:
                    post = item.operation
                case .delete:
                    delete = item.operation
                case .options:
                    options = item.operation
                case .head:
                    head = item.operation
                case .patch:
                    patch = item.operation
                case .trace:
                    trace = item.operation
                }
            }

            return .init(
                OpenAPI.PathItem(
                    get: get,
                    put: put,
                    post: post,
                    delete: delete,
                    options: options,
                    head: head,
                    patch: patch,
                    trace: trace
                )
            )
        }
    }
}
