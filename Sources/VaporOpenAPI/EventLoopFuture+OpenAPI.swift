//
//  EventLoopFuture+OpenAPI.swift
//  App
//
//  Created by Mathew Polzin on 12/8/19.
//

import Foundation
import NIO
import OpenAPIKit
import OpenAPIReflection

extension EventLoopFuture: OpenAPIEncodedSchemaType where Value: OpenAPIEncodedSchemaType {
    public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        return try Value.openAPISchema(using: encoder)
    }
}
