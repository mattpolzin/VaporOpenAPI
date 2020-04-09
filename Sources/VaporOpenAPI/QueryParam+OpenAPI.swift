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
    public func openAPIQueryParam() -> OpenAPI.PathItem.Parameter {
        let schema: OpenAPI.PathItem.Parameter.Schema

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

        let style: OpenAPI.PathItem.Parameter.Schema.Style
        let jsonSchema: JSONSchema
        switch swiftType {
        case let t as _Dictionary.Type:
            style = .deepObject
            jsonSchema = .object(
                additionalProperties: .init(guessJsonSchema(for: t.valueType))
            )
        case let t as _Array.Type:
            style = .form
            jsonSchema = .array(
                items: guessJsonSchema(for: t.elementType)
            )
        default:
            style = .form
            jsonSchema = guessJsonSchema(for: swiftType)
        }

        schema = .init(
            jsonSchema,
            style: style
        )

        return .init(
            name: name,
            parameterLocation: .query,
            schema: schema,
            description: description
        )
    }
}
