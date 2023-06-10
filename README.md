# VaporOpenAPI

This is currently in early stages of development, not a polished or feature-complete API by a long stretch.

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
