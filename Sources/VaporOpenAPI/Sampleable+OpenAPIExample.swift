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

public protocol OpenAPIExampleProvider: OpenAPIEncodedSchemaType {
    static func openAPIExample(using encoder: JSONEncoder) throws -> AnyCodable?
}

extension OpenAPIExampleProvider where Self: Encodable, Self: Sampleable {
    public static func openAPIExample(using encoder: JSONEncoder) throws -> AnyCodable? {
        let encodedSelf = try encoder.encode(sample)
        return try JSONDecoder().decode(AnyCodable.self, from: encodedSelf)
    }

    public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        return try genericOpenAPISchemaGuess(using: encoder)
    }
}
