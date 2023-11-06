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

/// Types that contain wrapped values (for OpenAPI conversion).
protocol _Wrapper {
    /// The wrapped type.
    static var wrappedType: Any.Type { get }
}

extension Optional: _Wrapper {
    static var wrappedType: Any.Type {
        return Wrapped.self
    }
}

extension AbstractRouteContext {
    /// The OpenAPI equivalents of any responses in the route context.
    /// - Returns: A `Response.Map` containing the converted responses.
    public static func openAPIResponses() throws -> OpenAPI.Response.Map {
        let encoder = try ContentConfiguration.global.openAPIJSONEncoder()

        return try self.openAPIResponses(using: encoder)
    }

    /// The OpenAPI equivalents of any responses in the route context.
    /// - Parameters:
    ///  - encoder: The `JSONEncoder` to generate the responses with.
    /// - Returns: A `Response.Map` containing the converted responses.
    public static func openAPIResponses(using encoder: JSONEncoder) throws -> OpenAPI.Response.Map {
        let responseTuples = try responseBodyTuples
            .compactMap { responseTuple -> (OpenAPI.Response.StatusCode, OpenAPI.Response)? in

                let statusCode = OpenAPI.Response.StatusCode.status(
                    code: responseTuple.statusCode
                )

                let responseReason = HTTPStatus(statusCode: responseTuple.statusCode)
                    .reasonPhrase

                if responseTuple.responseBodyType == EmptyResponseBody.self {
                    return (
                        statusCode,
                        OpenAPI.Response(
                            description: responseReason
                        )
                    )
                }

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
                if (contentType == .json || contentType == .jsonapi),
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
                let stringLikeTypes: [OpenAPI.ContentType?] = [
                    .any, .anyText, .css, .csv, .form, .html, .javascript, .json, .jsonapi, .multipartForm, .rtf, .txt, .xml, .yaml
                ]
                let binaryLikeTypes: [OpenAPI.ContentType?] = [
                    .anyApplication, .anyAudio, .anyImage, .anyVideo, .bmp, .jpg, .mov, .mp3, .mp4, .mpg, .pdf, .rar, .tar, .tif, .zip
                ]
                if stringLikeTypes.contains(contentType) {
                    schema = .string
                } else if binaryLikeTypes.contains(contentType) {
                    schema = .string(contentEncoding: .binary)
                } else {
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
    /// Generates the constructor for an OpenAPI `PathOperation` equivalent to the Vapor `Route`.
    func openAPIPathOperationConstructor() throws -> PathOperationConstructor {
        let encoder = try ContentConfiguration.global.openAPIJSONEncoder()

        return try self.openAPIPathOperationConstructor(using: encoder)
    }

    /// Generates the constructor for an OpenAPI `PathOperation` equivalent to the Vapor `Route`.
    /// - Parameters:
    ///   - encoder: The JSON encoder to generate the `PathOperationConstructor` with.
    func openAPIPathOperationConstructor(using encoder: JSONEncoder) throws -> PathOperationConstructor {
        let pathComponents = try OpenAPI.Path(
            path.map { try $0.openAPIPathComponent() }
        )

        let verb = try method.openAPIVerb()

        let requestBody = try openAPIRequest(for: requestType, using: encoder)

        let responses = try openAPIResponses(from: responseType, using: encoder)

        let pathParameters = path.compactMap { $0.openAPIPathParameter(in: self) }
        let queryParameters = openAPIQueryParams(from: responseType)

        let parameters = pathParameters
            + queryParameters

        return { context in

            let operation = OpenAPI.Operation(
                tags: context.tags,
                summary: context.summary,
                description: context.description,
                externalDocs: nil,
                operationId: nil,
                parameters: parameters.map { .init($0) },
                requestBody: requestBody,
                responses: responses,
                deprecated: context.deprecated,
                servers: nil
            )

            return (
                path: pathComponents,
                verb: verb,
                operation: operation
            )
        }
    }

    /// Generates an OpenAPI `PathOperation` equivalent to the Vapor `Route`.
    func openAPIPathOperation() throws -> PathOperation {
        let encoder = try ContentConfiguration.global.openAPIJSONEncoder()

        return try self.openAPIPathOperation(using: encoder)
    }

    /// Generates an OpenAPI `PathOperation` equivalent to the Vapor `Route`.
    /// - Parameters:
    ///   - encoder: An optional override JSON encoder to generate the `PathOperation` with. Otherwise, defaults to the ContentEncoder.
    func openAPIPathOperation(using encoder: JSONEncoder) throws -> PathOperation {
        let operation = try openAPIPathOperationConstructor(using: encoder)

        let summary = userInfo["openapi:summary"] as? String
        let description = userInfo["description"] as? String
        let tags = userInfo["openapi:tags"] as? [String]
        let deprecated = userInfo["openapi:deprecated"] as? Bool ?? false

        return operation(
            (
                summary: summary,
                description: description,
                tags: tags,
                deprecated: deprecated
            )
        )
    }

    /// Generates an array of OpenAPI parameters equivalent to the query params in the given response's body type.
    /// - Parameters:
    ///   - responseType: The type of response to get the query parameters from. Must be an `AbstractRouteContext` to extract query parameters.
    private func openAPIQueryParams(from responseType: Any.Type) -> [OpenAPI.Parameter] {
        if let responseBodyType = responseType as? AbstractRouteContext.Type {
            return responseBodyType
                .requestQueryParams
                .map { $0.openAPIQueryParam() }
        }

        return []
    }

    /// Generates the equivalent OpenAPI request for a given request type.
    /// - Parameters:
    ///   - requestType: The request body type to convert.
    func openAPIRequest(for requestType: Any.Type) throws -> OpenAPI.Request? {
        let encoder = try ContentConfiguration.global.openAPIJSONEncoder()

        return try self.openAPIRequest(for: requestType, using: encoder)
    }

    /// Generates the equivalent OpenAPI request for a given request type.
    /// - Parameters:
    ///   - requestType: The request body type to convert.
    ///   - encoder: A JSON encoder to generate the OpenAPI request with.
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

    /// Generates the equivalent OpenAPI request for a given request type.
    /// - Parameters:
    ///   - responseType: The response type to convert. If it conforms to `AbstractRouteContext`, this function will use all included responses.
    private func openAPIResponses(from responseType: Any.Type) throws -> OpenAPI.Response.Map {
        let encoder = try ContentConfiguration.global.openAPIJSONEncoder()

        return try self.openAPIResponses(from: responseType, using: encoder)
    }

    /// Generates the equivalent OpenAPI request for a given request type.
    /// - Parameters:
    ///   - responseType: The response type to convert. If it conforms to `AbstractRouteContext`, this function will use all included responses.
    ///   - encoder: The JSON encoder to generate the OpenAPI response map with.
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

/// Generates an example from a given type.
/// - Parameters:
///   - typeToSample: The type to generate a sample from. If it doesn't conform to `OpenAPIExampleProvider`, an example can't be generated.
///   - encoder: The JSON encoder to generate the example with.
private func reverseEngineeredExample(for typeToSample: Any.Type, using encoder: JSONEncoder) -> AnyCodable? {
    guard let exampleType = typeToSample as? OpenAPIExampleProvider.Type else {
        return nil
    }

    return try? exampleType.openAPIExample(using: encoder)
}

/// The context for an OpenAPI path operation.
/// - Parameters:
///   - summary: The summary of the path operation, if any.
///   - description: The longer description of the path operation, if any.
///   - tags: Any tags the path operation can have.
///   - deprecated: If `true`, then it marks the path operation as deprecated.
typealias PartialPathOperationContext = (
    summary: String?,
    description: String?,
    tags: [String]?,
    deprecated: Bool
)

/// A function that takes a `PartialPathOperationContext` and returns a `PathOperation`.
typealias PathOperationConstructor = (PartialPathOperationContext) -> PathOperation

/// A tuple containing a path, verb, and operation.
typealias PathOperation = (path: OpenAPI.Path, verb: OpenAPI.HttpMethod, operation: OpenAPI.Operation)


extension OpenAPI.Document: Content { }
