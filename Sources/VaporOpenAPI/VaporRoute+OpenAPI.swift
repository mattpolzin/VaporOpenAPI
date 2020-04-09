//
//  VaporRoute+OpenAPIEncodedNodeType.swift
//  AppAPIDocumentation
//
//  Created by Mathew Polzin on 10/19/19.
//

import Foundation
import OpenAPIKit
import OpenAPIReflection
import Vapor
import Sampleable

protocol _Wrapper {
    static var wrappedType: Any.Type { get }
}

extension Optional: _Wrapper {
    static var wrappedType: Any.Type {
        return Wrapped.self
    }
}

extension AbstractRouteContext {
    public static func openAPIResponses(using encoder: JSONEncoder) throws -> OpenAPI.Response.Map {

        let responseTuples = try responseBodyTuples
            .compactMap { responseTuple -> (OpenAPI.Response.StatusCode, OpenAPI.Response)? in

                let statusCode = OpenAPI.Response.StatusCode.status(
                    code: responseTuple.statusCode
                )

                let responseReason = HTTPStatus(statusCode: responseTuple.statusCode)
                    .reasonPhrase

                let contentType = responseTuple.contentType?.openAPIContentType

                let example = reverseEngineeredExample(for: responseTuple.responseBodyType, using: encoder)

                // first handle things explicitly supporting OpenAPI
                if let schema = try (responseTuple.responseBodyType as? OpenAPIEncodedSchemaType.Type)?.openAPISchema(using: encoder) {
                    return (
                        statusCode,
                        OpenAPI.Response(
                            description: responseReason,
                            content: [
                                (contentType ?? .json): .init(schema: .init(schema), example: example)
                            ]
                        )
                    )
                }

                // then try for a generic guess if the content type is JSON
                if contentType == .json,
                    let sample = (responseTuple.responseBodyType as? AbstractSampleable.Type)?.abstractSample,
                    let schema = try? genericOpenAPISchemaGuess(for: sample, using: encoder) {

                    return (
                        statusCode,
                        OpenAPI.Response(
                            description: responseReason,
                            content: [
                                (contentType ?? .json): .init(schema: .init(schema), example: example)
                            ]
                        )
                    )
                }

                // finally, handle binary files and give a wildly vague schema for anything else.
                let schema: JSONSchema
                switch contentType {
                case .all, .textAll, .css, .csv, .form, .html, .javascript, .json, .jsonapi, .multipartForm, .rtf, .txt, .xml, .yaml:
                    schema = .string
                case .applicationAll, .audioAll, .imageAll, .videoAll, .bmp, .jpg, .mov, .mp3, .mp4, .mpg, .pdf, .rar, .tar, .tif, .zip:
                    schema = .string(format: .binary)
                case .none:
                    schema = .string
                }

                return contentType.map {
                    OpenAPI.Response(
                        description: responseReason,
                        content: [
                            $0: .init(schema: .init(schema))
                        ]
                    )
                }.map { (statusCode, $0) }
        }

        return OrderedDictionary(
            responseTuples,
            uniquingKeysWith: { $1 }
        ).mapValues { .init($0) }
    }
}

extension Vapor.Route {

    func openAPIPathOperationConstructor(using encoder: JSONEncoder) throws -> PathOperationConstructor {
        let pathComponents = try OpenAPI.Path(
            path.map { try $0.openAPIPathComponent() }
        )

        let verb = try method.openAPIVerb()

        let requestBody = try openAPIRequest(for: requestType, using: encoder)

        let responses = try openAPIResponses(from: responseType, using: encoder)

        let pathParameters = path.compactMap { $0.openAPIPathParameter }
        let queryParameters = openAPIQueryParams(from: responseType)

        let parameters = pathParameters
            + queryParameters

        return { context in

            let operation = OpenAPI.PathItem.Operation(
                tags: context.tags,
                summary: context.summary,
                description: context.description,
                externalDocs: nil,
                operationId: nil,
                parameters: parameters.map { .init($0) },
                requestBody: requestBody,
                responses: responses,
                servers: nil
            )

            return (
                path: pathComponents,
                verb: verb,
                operation: operation
            )
        }
    }

    func openAPIPathOperation(using encoder: JSONEncoder) throws -> (path: OpenAPI.Path, verb: OpenAPI.HttpVerb, operation: OpenAPI.PathItem.Operation) {
        let operation = try openAPIPathOperationConstructor(using: encoder)

        let summary = userInfo["openapi:summary"] as? String
        let description = userInfo["description"] as? String
        let tags = userInfo["openapi:tags"] as? [String]

        return operation(
            (
                summary: summary,
                description: description,
                tags: tags
            )
        )
    }

    private func openAPIQueryParams(from responseType: Any.Type) -> [OpenAPI.PathItem.Parameter] {
        if let responseBodyType = responseType as? AbstractRouteContext.Type {
            return responseBodyType
                .requestQueryParams
                .map { $0.openAPIQueryParam() }
        }

        return []
    }

    private func openAPIRequest(for requestType: Any.Type, using encoder: JSONEncoder) throws -> OpenAPI.Request? {
        guard !(requestType is EmptyRequestBody.Type) else {
            return nil
        }

        let example = reverseEngineeredExample(for: requestType, using: encoder)

        let customRequestBodyType = (requestType as? OpenAPIEncodedSchemaType.Type)
            ?? ((requestType as? _Wrapper.Type)?.wrappedType as? OpenAPIEncodedSchemaType.Type)

        guard let requestBodyType = customRequestBodyType else {
            return nil
        }

        let schema = try requestBodyType.openAPISchema(using: encoder)

        return OpenAPI.Request(
            content: [
                .json: .init(schema: .init(schema), example: example)
            ]
        )
    }

    private func openAPIResponses(from responseType: Any.Type, using encoder: JSONEncoder) throws -> OpenAPI.Response.Map {

        if let responseBodyType = responseType as? AbstractRouteContext.Type {
            return try responseBodyType.openAPIResponses(using: encoder)
        }

        let responseBodyType = (responseType as? OpenAPIEncodedSchemaType.Type)
            ?? ((responseType as? _Wrapper.Type)?.wrappedType as? OpenAPIEncodedSchemaType.Type)

        let successResponse = try responseBodyType
            .map { responseType -> OpenAPI.Response in
                let schema = try responseType.openAPISchema(using: encoder)

                return .init(
                    description: "Success",
                    content: [
                        .json: .init(schema: .init(schema))
                    ]
                )
        }

        let responseTuples = [
            successResponse.map{ (OpenAPI.Response.StatusCode(200), $0) }
        ].compactMap { $0 }

        return OrderedDictionary(
            responseTuples,
            uniquingKeysWith: { $1 }
        ).mapValues { .init($0) }
    }
}

private func reverseEngineeredExample(for typeToSample: Any.Type, using encoder: JSONEncoder) -> AnyCodable? {
    guard let exampleType = typeToSample as? OpenAPIExampleProvider.Type else {
        return nil
    }

    return try? exampleType.openAPIExample(using: encoder)
}

typealias PartialPathOperationContext = (
    summary: String?,
    description: String?,
    tags: [String]?
)

typealias PathOperationConstructor = (PartialPathOperationContext) -> (path: OpenAPI.Path, verb: OpenAPI.HttpVerb, operation: OpenAPI.PathItem.Operation)
