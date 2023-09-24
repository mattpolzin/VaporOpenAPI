import XCTest
import OpenAPIReflection
import VaporOpenAPI
import Sampleable
import XCTVapor

final class VaporOpenAPITests: XCTestCase {
    func testExample() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.get("hello", use: TestController.indexRoute)
        app.post("hello", use: TestController.createRoute)
        app.get(
            "hello",
            ":id".parameterType(Int.self).description("hello world"),
            use: TestController.showRoute
        )
        app.delete("hello", use: TestController.deleteRoute)
        app.post("hello", "empty", use: TestController.createEmptyReturn)

        try testRoutes(on: app)
    }

    func testAsyncExample() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.get("hello", use: AsyncTestController.indexRoute)
        app.post("hello", use: AsyncTestController.createRoute)
        app.get(
            "hello",
            ":id".parameterType(Int.self).description("hello world"),
            use: AsyncTestController.showRoute
        )
        app.delete("hello", use: AsyncTestController.deleteRoute)
        app.post("hello", "empty", use: AsyncTestController.createEmptyReturn)

        try testRoutes(on: app)
    }

    /// Just the route-checking bits in their own function so we can test out EventLoopFuture handling and async/await cleanly.
    func testRoutes(on app: Application) throws {
        let info = OpenAPI.Document.Info(
            title: "Vapor OpenAPI Test API",
            description:
"""
## Descriptive Text
This text supports _markdown_!
""",
            version: "1.0"
        )

        let portString = "\(app.http.server.configuration.port == 80 ? "" : ":\(app.http.server.configuration.port)")"

        let servers = [
            OpenAPI.Server(url: URL(string: "http://\(app.http.server.configuration.hostname)\(portString)")!)
        ]

        let components = OpenAPI.Components(
            schemas: [:],
            responses: [:],
            parameters: [:],
            examples: [:],
            requestBodies: [:],
            headers: [:]
        )

        let paths = try app.routes.openAPIPathItems()

        let document = OpenAPI.Document(
            info: info,
            servers: servers,
            paths: paths,
            components: components,
            security: []
        )

        XCTAssertEqual(document.paths.count, 3)
        XCTAssertNotNil(document.paths["/hello"]?.pathItemValue?.get)
        XCTAssertNotNil(document.paths["/hello"]?.pathItemValue?.post)
        XCTAssertNotNil(document.paths["/hello"]?.pathItemValue?.delete)
        XCTAssertNil(document.paths["/hello"]?.pathItemValue?.put)
        XCTAssertNil(document.paths["/hello"]?.pathItemValue?.patch)
        XCTAssertNil(document.paths["/hello"]?.pathItemValue?.head)
        XCTAssertNil(document.paths["/hello"]?.pathItemValue?.options)
        XCTAssertNil(document.paths["/hello"]?.pathItemValue?.trace)
        XCTAssertNotNil(document.paths["/hello/{id}"]?.pathItemValue?.get)

        XCTAssertNotNil(document.paths["/hello"]?.pathItemValue?.get?.responses[.status(code: 200)])
        XCTAssertNotNil(document.paths["/hello"]?.pathItemValue?.get?.responses[.status(code: 400)])
        XCTAssertNotNil(document.paths["/hello"]?.pathItemValue?.delete?.responses[.status(code: 204)])

        XCTAssertNotNil(document.paths["/hello/empty"]?.pathItemValue?.post?.responses[.status(code: 201)])

        XCTAssertEqual(document.paths["/hello/{id}"]?.pathItemValue?.get?.parameters[0].parameterValue?.description, "hello world")
        XCTAssertEqual(document.paths["/hello/{id}"]?.pathItemValue?.get?.parameters[0].parameterValue?.schemaOrContent.schemaValue, .integer)

        let requestExample = document.paths["/hello"]?.pathItemValue?.post?.requestBody?.b?.content[.json]?.example
        XCTAssertNotNil(requestExample)
        XCTAssertNotNil(document.paths["/hello"]?.pathItemValue?.post?.responses[.status(code: 201)])
        let requestExampleDict = requestExample?.value as? [String: Any]
        XCTAssertNotNil(requestExampleDict, "Expected request example to decode as a dictionary from String to Any")

        XCTAssertEqual(requestExampleDict?["stringValue"] as? String, "hello world!")
    }
}

struct CreatableResource: Codable, Sampleable, OpenAPIExampleProvider {
    let stringValue: String

    static let sample: Self = .init(stringValue: "hello world!")
}

struct TestIndexRouteContext: RouteContext {
    typealias RequestBodyType = EmptyRequestBody

    static let defaultContentType: HTTPMediaType? = nil

    static let shared = Self()

    let echo: IntegerQueryParam = .init(name: "echo")

    let success: ResponseContext<String> = .init { response in
        response.headers = Self.plainTextHeader
        response.status = .ok
    }

    let badRequest: CannedResponse<String> = .init(
        response: Response(
            status: .badRequest,
            headers: Self.plainTextHeader,
            body: .empty
        )
    )

    static let plainTextHeader = HTTPHeaders([
        (HTTPHeaders.Name.contentType.description, HTTPMediaType.plainText.serialize())
    ])
}

struct TestShowRouteContext: RouteContext {
    typealias RequestBodyType = EmptyRequestBody

    static let defaultContentType: HTTPMediaType? = nil

    static let shared = Self()

    let badQuery: StringQueryParam = .init(name: "failHard")
    let echo: IntegerQueryParam = .init(name: "echo")

    let success: ResponseContext<String> = .init { response in
        response.headers = Self.plainTextHeader
        response.status = .ok
    }

    let badRequest: CannedResponse<String> = .init(
        response: Response(
            status: .badRequest,
            headers: Self.plainTextHeader,
            body: .empty
        )
    )

    static let plainTextHeader = HTTPHeaders([
        (HTTPHeaders.Name.contentType.description, HTTPMediaType.plainText.serialize())
    ])
}

struct TestCreateRouteContext: RouteContext {
    typealias RequestBodyType = CreatableResource

    static let defaultContentType: HTTPMediaType? = nil

    static let shared = Self()

    let badQuery: StringQueryParam = .init(name: "failHard")

    let success: ResponseContext<String> = .init { response in
        response.headers = Self.plainTextHeader
        response.status = .created
    }

    let badRequest: CannedResponse<String> = .init(
        response: Response(
            status: .badRequest,
            headers: Self.plainTextHeader,
            body: .empty
        )
    )

    static let plainTextHeader = HTTPHeaders([
        (HTTPHeaders.Name.contentType.description, HTTPMediaType.plainText.serialize())
    ])
}

struct TestDeleteRouteContext: RouteContext {
    typealias RequestBodyType = EmptyRequestBody

    static let defaultContentType: HTTPMediaType? = nil

    static let shared = Self()

    let success: ResponseContext<EmptyResponseBody> = .init { response in
        response.status = .noContent
    }
}

struct TestCreateEmptyReturnRouteContext: RouteContext {
    typealias RequestBodyType = CreatableResource

    static let defaultContentType: HTTPMediaType? = nil

    static let shared = Self()

    let success: ResponseContext<EmptyResponseBody> = .init { response in
        response.status = .created
    }
}

final class TestController {
    static func indexRoute(_ req: TypedRequest<TestIndexRouteContext>) -> EventLoopFuture<Response> {
        if let text = req.query.echo {
            return req.response.success.encode("\(text)")
        }
        return req.response.success.encode("Hello")
    }

    static func showRoute(_ req: TypedRequest<TestShowRouteContext>) -> EventLoopFuture<Response> {
        if req.query.badQuery != nil {
            return req.response.badRequest
        }
        if let text = req.query.echo {
            return req.response.success.encode("\(text)")
        }
        return req.response.success.encode("Hello")
    }

    static func createRoute(_ req: TypedRequest<TestCreateRouteContext>) -> EventLoopFuture<Response> {
        if req.query.badQuery != nil {
            return req.response.badRequest
        }
        return req.response.success.encode("Hello")
    }

    static func deleteRoute(_ req: TypedRequest<TestDeleteRouteContext>) -> EventLoopFuture<Response> {
        return req.response.success.encodeEmptyResponse()
    }
    
    static func createEmptyReturn(_ req: TypedRequest<TestCreateEmptyReturnRouteContext>) -> EventLoopFuture<Response> {
        return req.response.success.encodeEmptyResponse()
    }
}

final class AsyncTestController {
    static func indexRoute(_ req: TypedRequest<TestIndexRouteContext>) async throws -> Response {
        if let text = req.query.echo {
            return try await req.response.success.encode("\(text)")
        }
        return try await req.response.success.encode("Hello")
    }

    static func showRoute(_ req: TypedRequest<TestShowRouteContext>) async throws -> Response {
        if req.query.badQuery != nil {
            return try await req.response.get(\.badRequest)
        }
        if let text = req.query.echo {
            return try await req.response.success.encode("\(text)")
        }
        return try await req.response.success.encode("Hello")
    }

    static func createRoute(_ req: TypedRequest<TestCreateRouteContext>) async throws -> Response {
        if req.query.badQuery != nil {
            return try await req.response.get(\.badRequest)
        }
        return try await req.response.success.encode("Hello")
    }

    static func deleteRoute(_ req: TypedRequest<TestDeleteRouteContext>) async throws -> Response {
        return try await req.response.success.encodeEmptyResponse()
    }

    static func createEmptyReturn(_ req: TypedRequest<TestCreateEmptyReturnRouteContext>) async throws -> Response {
        return try await req.response.success.encodeEmptyResponse()
    }
}
