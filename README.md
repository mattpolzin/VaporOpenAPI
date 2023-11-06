# VaporOpenAPI

This is more of a prototype of a library, not a polished or feature-complete API by a long stretch. That said, folks have found it useful and I certainly encourage you to PR fixes and improvements if you also find this library useful!

As of the release of OpenAPIKit v3.0.0, this library produces OpenAPI v3.1 compatible documents instead of OpenAPI v3.0 compatible documents.

See https://github.com/mattpolzin/VaporOpenAPIExample for an example of a simple app using this library.

You use `VaporTypedRoutes.TypedRequest` instead of `Vapor.Request` to form a request context that can be used to build out an OpenAPI description. You use custom methods to attach your routes to the app. These methods mirror the methods available in Vapor already.

You can use the library like this with Swift Concurrency:

```swift
enum WidgetController {
    struct ShowRoute: RouteContext {
        ...
    }
    
    static func show(_ req: TypedRequest<ShowRoute>) try await -> Response {
        ...
    }
}

func routes(_ app: Application) {
    app.get(
        "widgets",
        ":type".description("The type of widget"),
        ":id".parameterType(Int.self),
        use: WidgetController.show 
    ).tags("Widgets")
      .summary("Get a widget")
}
```

...and like this with a NIO EventLoopFuture:

```swift
enum WidgetController {
    struct ShowRoute: RouteContext {
        ...
    }
    
    static func show(_ req: TypedRequest<ShowRoute>) -> EventLoopFuture<Response> {
        ...
    }
}

func routes(_ app: Application) {
    app.get(
        "widgets",
        ":type".description("The type of widget"),
        ":id".parameterType(Int.self),
        use: WidgetController.show 
    ).tags("Widgets")
      .summary("Get a widget")
}
```
