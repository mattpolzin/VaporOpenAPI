//
//  Route+Metadata.swift
//  VaporOpenAPI
//
//  Created by Mathew Polzin on 12/6/19.
//

import Vapor

//
// These extensions provide an easy way to add
// metadata to routes at the defintion site.
//
// For example:
//
// routes.get("hello world") { return "hello world" }
//   .summary("Says hello")
//   .tags("Greetings")
//
extension Route {
    // NOTE `func description(_:)` exists out-of-box.

    /// Add an OpenAPI-compatible summary to the route.
    @discardableResult
    public func summary(_ summary: String) -> Route {
        userInfo["openapi:summary"] = summary
        return self
    }

    /// Add OpenAPI-compatible tags to the route.
    @discardableResult
    public func tags(_ tags: String...) -> Route {
        return self.tags(tags)
    }

    /// Add OpenAPI-compatible tags to the route.
    @discardableResult
    public func tags(_ tags: [String]) -> Route {
        userInfo["openapi:tags"] = tags
        return self
    }
    
    /// Add OpenAPI-compatible deprecation notice to the route.
    @discardableResult
    public func deprecated() -> Route {
        userInfo["openapi:deprecated"] = true
        return self
    }
}
