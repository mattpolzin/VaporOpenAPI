//
//  QueryParam+OpenAPI.swift
//  AppAPIDocumentation
//
//  Created by Mathew Polzin on 12/8/19.
//

import OpenAPIKit

protocol _Array {
    static var elementType: Any.Type { get }
}
extension Array: _Array {
    static var elementType: Any.Type {
        return Element.self
    }
}

protocol _Dictionary {
    static var valueType: Any.Type { get }
}
extension Dictionary: _Dictionary {
    static var valueType: Any.Type {
        return Value.self
    }
}

extension AbstractQueryParam {
    public func openAPIQueryParam() -> OpenAPI.Parameter {
        let schema: OpenAPI.Parameter.SchemaContext

        func guessJsonSchema(for type: Any.Type) -> JSONSchema {
            guard let schemaType = type as? OpenAPISchemaType.Type else {
                    return .string
            }
            let ret = schemaType.openAPISchema
            guard let allowedValues = self.allowedValues else {
                return ret
            }

            return ret.with(allowedValues: allowedValues.map { AnyCodable($0) })
        }

        let style: OpenAPI.Parameter.SchemaContext.Style
        let explode: Bool
        let jsonSchema: JSONSchema
        switch swiftType {
        case let t as _Dictionary.Type:
            style = .deepObject
            explode = true
            jsonSchema = .object(
                additionalProperties: .init(guessJsonSchema(for: t.valueType))
            )
        case let t as _Array.Type:
            style = .form
            explode = false
            jsonSchema = .array(
                items: guessJsonSchema(for: t.elementType)
            )
        default:
            style = .form
            explode = true
            jsonSchema = guessJsonSchema(for: swiftType)
        }

        schema = .init(
            jsonSchema,
            style: style,
            explode: explode
        )

        return .init(
            name: name,
            context: .query,
            schema: schema,
            description: description
        )
    }
}
