//
//  RoutesBuilder+OpenAPI+RouteContext.swift
//  
//
//  Created by Mathew Polzin on 5/8/20.
//

import Vapor
import VaporTypedRoutes

public final class OpenAPIRoutesBuilder {
    private let routes: Routes

    internal init(routes: Routes) {
        self.routes = routes
    }

    public func add(openAPIRoute: Route) {
        routes.add(openAPIRoute)
    }
}

extension Application {
    public var openAPI: OpenAPIRoutesBuilder {
        return .init(routes: self.routes)
    }
}

extension OpenAPIRoutesBuilder {

    @discardableResult
    public func get<Context, Response>(
        _ path: OpenAPIPathComponent...,
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
    {
        return self.on(.GET, path, use: closure)
    }

    @discardableResult
    public func post<Context, Response>(
        _ path: OpenAPIPathComponent...,
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
    {
        return self.on(.POST, path, use: closure)
    }

    @discardableResult
    public func patch<Context, Response>(
        _ path: OpenAPIPathComponent...,
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
    {
        return self.on(.PATCH, path, use: closure)
    }

    @discardableResult
    public func put<Context, Response>(
        _ path: OpenAPIPathComponent...,
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
    {
        return self.on(.PUT, path, use: closure)
    }

    @discardableResult
    public func delete<Context, Response>(
        _ path: OpenAPIPathComponent...,
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
    {
        return self.on(.DELETE, path, use: closure)
    }

    @discardableResult
    public func on<Context, Response>(
        _ method: HTTPMethod,
        _ path: [OpenAPIPathComponent],
        body: HTTPBodyStreamStrategy = .collect,
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
    {
        let wrappingClosure = { (request: Vapor.Request) -> Response in
            return try closure(.init(underlyingRequest: request))
        }

        let responder = BasicResponder { request in
            if case .collect(let max) = body, request.body.data == nil {
                return request.body.collect(max: max?.value ?? request.application.routes.defaultMaxBodySize.value).flatMapThrowing { _ in
                    return try wrappingClosure(request)
                }.encodeResponse(for: request)
            } else {
                return try wrappingClosure(request)
                    .encodeResponse(for: request)
            }
        }

        let route = Route(
            method: method,
            path: path.map(\.vaporPathComponent),
            responder: responder,
            requestType: Context.RequestBodyType.self,
            responseType: Context.self
        )

        for component in path {
            guard case let .parameter(name, optionalDescription) = component,
                let description = optionalDescription else {
                    continue
            }
            route.userInfo["openapi:parameter:\(name)"] = description
        }

        self.add(openAPIRoute: route)

        return route
    }
}
