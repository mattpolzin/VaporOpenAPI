//
//  Sampleable+OpenAPIExample.swift
//  
//
//  Created by Mathew Polzin on 3/21/20.
//

import Foundation
import OpenAPIKit
import OpenAPIReflection
import Sampleable
import Vapor

/// Types that provide an example for the OpenAPI definition.
public protocol OpenAPIExampleProvider: OpenAPIEncodedSchemaType {
    /// The example for the OpenAPI schema.
    /// - Parameters:
    ///   - encoder: The encoder to use to generate the OpenAPI example with.
    static func openAPIExample(using encoder: JSONEncoder) throws -> AnyCodable?
}

extension OpenAPIExampleProvider where Self: Encodable, Self: Sampleable {
    /// The example for the OpenAPI schema.
    public static func openAPIExample() throws -> AnyCodable? {
        let encoder = try ContentConfiguration.global.openAPIJSONEncoder()

        return try self.openAPIExample(using: encoder)
    }

    // Automatically implement the OpenAPI example for types conforming to Encodable and Sampleable.
    public static func openAPIExample(using encoder: JSONEncoder) throws -> AnyCodable? {
        let encodedSelf = try encoder.encode(sample)
        return try JSONDecoder().decode(AnyCodable.self, from: encodedSelf)
    }

    /// Get the OpenAPI schema for the `OpenAPIExampleProvider`.
    public static func openAPISchema() throws -> JSONSchema {
        let encoder = try ContentConfiguration.global.openAPIJSONEncoder()

        return try self.openAPISchema(using: encoder)
    }

    /// Get the OpenAPI schema for the `OpenAPIExampleProvider`.
    public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        return try genericOpenAPISchemaGuess(using: encoder)
    }
}
