//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

class GraphQLResponseDecoderTests: XCTestCase {
    static let decoder = JSONDecoder()
    static let encoder = JSONEncoder()

    override class func setUp() {
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
    }

    struct SimpleModel: Model {
        public let id: String

        public init(id: String = UUID().uuidString) {
            self.id = id
        }

        public enum CodingKeys: String, ModelKey {
            case id
        }

        public static let keys = CodingKeys.self

        public static let schema = defineSchema { model in
            let post = Post.keys
            model.pluralName = "SimpleModels"
            model.fields(
                .id()
            )
        }
    }

    func testDecodeToGraphQLResponseWhenDataOnly() throws {
        let request = GraphQLRequest<String>(document: "",
                                             responseType: String.self,
                                             decodePath: "getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "data": [
                "getSimpleModel": [
                    "id": "id"
                ]
            ]
        ]
        let data = try GraphQLResponseDecoderTests.encoder.encode(graphQLData)
        decoder.appendResponse(data)

        let result = try decoder.decodeToGraphQLResponse()

        guard case let .success(response) = result else {
            XCTFail("Could not get successful response")
            return
        }
        XCTAssertEqual(response, "{\"id\":\"id\"}")
    }

    func testDecodeToGraphQLResponseWhenErrorsOnly() throws {
        let request = GraphQLRequest<String>(document: "",
                                             responseType: String.self,
                                             decodePath: "getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "errors": [
                ["message": "message1"],
                ["message": "message2"]
            ]
        ]
        let data = try GraphQLResponseDecoderTests.encoder.encode(graphQLData)
        decoder.appendResponse(data)

        let result = try decoder.decodeToGraphQLResponse()

        guard case let .failure(response) = result,
              case .error = response else {
            XCTFail("Could not get failure response")
            return
        }
    }

    func testDecodeToGraphQLResponseWhenDataAndErrors() throws {
        let request = GraphQLRequest<String>(document: "",
                                             responseType: String.self,
                                             decodePath: "getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "data": [
                "getSimpleModel": [
                    "id": "id"
                ]
            ],
            "errors": [
                ["message": "message1"],
                ["message": "message2"]
            ]
        ]
        let data = try GraphQLResponseDecoderTests.encoder.encode(graphQLData)
        decoder.appendResponse(data)

        let result = try decoder.decodeToGraphQLResponse()

        guard case let .failure(response) = result,
              case .partial = response else {
            XCTFail("Could not get failure response")
            return
        }
    }

    func testDecodeToGraphQLResponseWhenInvalidResponse() throws {
        let request = GraphQLRequest<String>(document: "",
                                             responseType: String.self,
                                             decodePath: "getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "invalidDataKey": [
                "getSimpleModel": [
                    "id": "id"
                ]
            ],
            "invalidErrorsKey": [
                ["message": "message1"],
                ["message": "message2"]
            ]
        ]
        let data = try GraphQLResponseDecoderTests.encoder.encode(graphQLData)
        decoder.appendResponse(data)

        do {
            _ = try decoder.decodeToGraphQLResponse()
            XCTFail("Should fail in catch block")
        } catch let error as APIError {
            guard case .unknown = error else {
                XCTFail("Unexpected error \(error)")
                return
            }
        } catch {
            XCTFail("Should have been APIError")
        }
    }

    func testDecodeToGraphQLResponseWhenPartialAndDataIsNull() throws {
        let request = GraphQLRequest<String>(document: "",
                                             responseType: String.self,
                                             decodePath: "getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "data": [
                "getSimpleModel": JSONValue.null
            ],
            "errors": [
                ["message": "message1"],
                ["message": "message2"]
            ]
        ]
        let data = try GraphQLResponseDecoderTests.encoder.encode(graphQLData)
        decoder.appendResponse(data)

        let result = try decoder.decodeToGraphQLResponse()

        guard case let .failure(response) = result,
              case .error = response else {
            XCTFail("Could not get failure response")
            return
        }
    }
}
