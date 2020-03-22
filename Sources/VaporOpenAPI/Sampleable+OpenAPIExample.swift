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
    static func openAPIExample(using encoder: JSONEncoder) throws -> String?
}

extension OpenAPIExampleProvider where Self: Encodable, Self: Sampleable {
    public static func openAPIExample(using encoder: JSONEncoder) throws -> String? {
        let encodedSelf = try encoder.encode(sample)
        return String(data: encodedSelf, encoding: .utf8)
    }

    public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        return try genericOpenAPISchemaGuess(using: encoder)
    }
}
