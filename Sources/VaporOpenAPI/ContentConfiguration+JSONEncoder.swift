//
//  ContentConfiguration+JSONEncoder.swift
//  
//
//  Created by Charlie Welsh on 9/16/22.
//

import Vapor

extension ContentConfiguration {
    /// The configured JSON encoder for the content configuration.
    func jsonEncoder() throws -> JSONEncoder {
        guard let encoder = try self
            .requireEncoder(for: .json)
                as? JSONEncoder
        else {
            // This is an Abort since this is an error with a Vapor component.
            throw Abort(
                .internalServerError, reason: "Couldn't get encoder for OpenAPI schema.")
        }

        return encoder
    }

    /// The content JSON encoder, but with the settings to encode an OpenAPI schema.
    func openAPIJSONEncoder() throws -> JSONEncoder {
        let encoder = try self.jsonEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys

        return encoder
    }
}
