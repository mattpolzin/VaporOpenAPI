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

/// Types that provide an example for the OpenAPI definition.
public protocol OpenAPIExampleProvider: OpenAPIEncodedSchemaType {
	/// The example for the OpenAPI schema.
    static func openAPIExample(using encoder: JSONEncoder) throws -> AnyCodable?
}

extension OpenAPIExampleProvider where Self: Encodable, Self: Sampleable {
	// Automatically implement the OpenAPI example for types conforming to Encodable and Sampleable.
    public static func openAPIExample(using encoder: JSONEncoder) throws -> AnyCodable? {
        let encodedSelf = try encoder.encode(sample)
        return try JSONDecoder().decode(AnyCodable.self, from: encodedSelf)
    }

	/// Get the OpenAPI schema for the `OpenAPIExampleProvider`.
    public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        return try genericOpenAPISchemaGuess(using: encoder)
    }
}
