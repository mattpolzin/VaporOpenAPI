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

        // TODO: Add support for ContentEncoder to JSONAPIOpenAPI
        let jsonEncoder = JSONEncoder()
        if #available(macOS 10.12, *) {
            jsonEncoder.dateEncodingStrategy = .iso8601
            jsonEncoder.outputFormatting = .sortedKeys
        }
        #if os(Linux)
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonEncoder.outputFormatting = .sortedKeys
        #endif

        let info = OpenAPI.Document.Info(
            title: "Vapor OpenAPI Test API",
            description:
"""
## Descriptive Text
This text supports _markdown_!
""",
            version: "1.0"
        )

        // TODO: get hostname & port from environment
        let servers = [
            OpenAPI.Server(url: URL(string: "http://localhost")!)
        ]

        let components = OpenAPI.Components(
            schemas: [:],
            responses: [:],
            parameters: [:],
            examples: [:],
            requestBodies: [:],
            headers: [:]
        )

        let paths = try app.routes.openAPIPathItems(using: jsonEncoder)

        let document = OpenAPI.Document(
            info: info,
            servers: servers,
            paths: paths,
            components: components,
            security: []
        )

        XCTAssertEqual(document.paths.count, 2)
        XCTAssertNotNil(document.paths["/hello"]?.get)
        XCTAssertNotNil(document.paths["/hello"]?.post)
        XCTAssertNotNil(document.paths["/hello"]?.delete)
        XCTAssertNil(document.paths["/hello"]?.put)
        XCTAssertNil(document.paths["/hello"]?.patch)
        XCTAssertNil(document.paths["/hello"]?.head)
        XCTAssertNil(document.paths["/hello"]?.options)
        XCTAssertNil(document.paths["/hello"]?.trace)
        XCTAssertNotNil(document.paths["/hello/{id}"]?.get)

        XCTAssertNotNil(document.paths["/hello"]?.get?.responses[.status(code: 200)])
        XCTAssertNotNil(document.paths["/hello"]?.get?.responses[.status(code: 400)])
        XCTAssertNotNil(document.paths["/hello"]?.delete?.responses[.status(code: 204)])

        XCTAssertEqual(document.paths["/hello/{id}"]?.get?.parameters[0].parameterValue?.description, "hello world")
        XCTAssertEqual(document.paths["/hello/{id}"]?.get?.parameters[0].parameterValue?.schemaOrContent.schemaValue, .integer)

        let requestExample = document.paths["/hello"]?.post?.requestBody?.b?.content[.json]?.example
        XCTAssertNotNil(requestExample)
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

struct TestDeleteRouteContext: RouteContext {
    typealias RequestBodyType = EmptyRequestBody

    static let defaultContentType: HTTPMediaType? = nil

    static let shared = Self()

    let success: ResponseContext<EmptyResponseBody> = .init { response in
        response.status = .noContent
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
}
