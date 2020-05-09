//
//  OpenAPIPathComponent.swift
//  
//
//  Created by Mathew Polzin on 5/8/20.
//

import Vapor
import OpenAPIKit

public enum OpenAPIPathComponent: ExpressibleByStringLiteral, CustomStringConvertible {
    case constant(String)
    case parameter(name: String, description: String?)
    case anything
    case catchall

    public init(stringLiteral value: StringLiteralType) {
        switch Vapor.PathComponent(stringLiteral: value) {
        case .constant(let value):
            self = .constant(value)
        case .parameter(let name):
            self = .parameter(name: name, description: nil)
        case .anything:
            self = .anything
        case .catchall:
            self = .catchall
        }
    }

    public var description: String {
        switch self {
        case .anything:
            return Vapor.PathComponent.anything.description
        case .catchall:
            return Vapor.PathComponent.catchall.description
        case .parameter(name: let value, description: _):
            return Vapor.PathComponent.parameter(value).description
        case .constant(let value):
            return Vapor.PathComponent.constant(value).description
        }
    }

    public var vaporPathComponent: Vapor.PathComponent {
        switch self {
        case .anything:
            return .anything
        case .catchall:
            return .catchall
        case .parameter(name: let name, description: _):
            return .parameter(name)
        case .constant(let value):
            return .constant(value)
        }
    }
}

extension OpenAPIPathComponent {
    public static func parameter(_ name: String) -> Self {
        return .parameter(name: name, description: nil)
    }

    /// Add an OpenAPI description to this path component.
    ///
    /// This only has an effect on path components that
    /// are parameters.
    public func description(_ description: String) -> Self {
        guard case let .parameter(name, _) = self else {
            return self
        }
        return .parameter(name: name, description: description)
    }
}

extension String {
    public func description(_ string: String) -> OpenAPIPathComponent {
        let component = OpenAPIPathComponent(stringLiteral: self)
        guard case let .parameter(name, _) = component else {
            return component
        }
        return .parameter(name: name, description: string)
    }
}

extension Array where Element == OpenAPIPathComponent {
    public var string: String {
        self.map(\.description).joined(separator: "/")
    }
}
