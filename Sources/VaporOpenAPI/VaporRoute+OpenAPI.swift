//
//  VaporRoute+OpenAPIEncodedNodeType.swift
//  AppAPIDocumentation
//
//  Created by Mathew Polzin on 10/19/19.
//

import Foundation
import OpenAPIKit
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

                // first handle things explicitly supporting OpenAPI
                if let schema = try (responseTuple.responseBodyType as? OpenAPIEncodedNodeType.Type)?.openAPINode(using: encoder) {
                    return (
                        statusCode,
                        OpenAPI.Response(
                            description: responseReason,
                            content: [
                                (contentType ?? .json): .init(schema: .init(schema))
                            ]
                        )
                    )
                }

                // then try for a generic guess if the content type is JSON
                if contentType == .json,
                    let sample = (responseTuple.responseBodyType as? AbstractSampleable.Type)?.abstractSample,
                    let schema = try? genericOpenAPINode(for: sample, using: encoder) {

                    return (
                        statusCode,
                        OpenAPI.Response(
                            description: responseReason,
                            content: [
                                (contentType ?? .json): .init(schema: .init(schema))
                            ]
                        )
                    )
                }

                // finally, handle binary files and give a wildly vague schema for anything else.
                let schema: JSONSchema
                switch contentType {
                case .css, .csv, .form, .html, .javascript, .json, .jsonapi, .multipartForm, .txt, .xml:
                    schema = .string
                case .pdf, .rar, .tar, .zip:
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

        return Dictionary(
            responseTuples,
            uniquingKeysWith: { $1 }
        ).mapValues { .init($0) }
    }
}

extension Vapor.Route {
    func openAPIPathOperationConstructor(using encoder: JSONEncoder) throws -> PathOperationConstructor {
        let pathComponents = try OpenAPI.PathComponents(
            path.map { try $0.openAPIPathComponent() }
        )

        let verb = try method.openAPIVerb()

        let requestBodyType = (requestType as? OpenAPIEncodedNodeType.Type)
            ?? ((requestType as? _Wrapper.Type)?.wrappedType as? OpenAPIEncodedNodeType.Type)

        let requestBody = try requestBodyType
            .map { requestType -> OpenAPI.Request in
                let schema = try requestType.openAPINode(using: encoder)

                return OpenAPI.Request(
                    content: [
                        .json: .init(schema: .init(schema))
                    ]
                )
        }

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

    func openAPIPathOperation(using encoder: JSONEncoder) throws -> (path: OpenAPI.PathComponents, verb: OpenAPI.HttpVerb, operation: OpenAPI.PathItem.Operation) {
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

    private func openAPIResponses(from responseType: Any.Type, using encoder: JSONEncoder) throws -> OpenAPI.Response.Map {

        if let responseBodyType = responseType as? AbstractRouteContext.Type {
            return try responseBodyType.openAPIResponses(using: encoder)
        }

        let responseBodyType = (responseType as? OpenAPIEncodedNodeType.Type)
            ?? ((responseType as? _Wrapper.Type)?.wrappedType as? OpenAPIEncodedNodeType.Type)

        let successResponse = try responseBodyType
            .map { responseType -> OpenAPI.Response in
                let schema = try responseType.openAPINode(using: encoder)

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

        return Dictionary(
            responseTuples,
            uniquingKeysWith: { $1 }
        ).mapValues { .init($0) }
    }
}

typealias PartialPathOperationContext = (
    summary: String?,
    description: String?,
    tags: [String]?
)

typealias PathOperationConstructor = (PartialPathOperationContext) -> (path: OpenAPI.PathComponents, verb: OpenAPI.HttpVerb, operation: OpenAPI.PathItem.Operation)
