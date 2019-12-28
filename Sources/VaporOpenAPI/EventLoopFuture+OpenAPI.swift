//
//  EventLoopFuture+OpenAPI.swift
//  App
//
//  Created by Mathew Polzin on 12/8/19.
//

import Foundation
import NIO
import OpenAPIKit

extension EventLoopFuture: OpenAPIEncodedNodeType where Value: OpenAPIEncodedNodeType {
    public static func openAPINode(using encoder: JSONEncoder) throws -> JSONSchema {
        return try Value.openAPINode(using: encoder)
    }
}
