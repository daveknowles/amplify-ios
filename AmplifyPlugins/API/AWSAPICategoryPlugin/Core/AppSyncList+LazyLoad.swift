//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

extension AppSyncList {
    /// Represents the data state of the `AppSyncList`.
    internal enum LoadState {
        case pending
        case loaded
    }

    func firstPage(_ completion: @escaping (Result<Void, CoreError>) -> Void) {
        let request = constructGraphQLRequestForFirstPage()
        Amplify.API.query(request: request) { result in
            switch result {
            case .success(let graphQLResponse):
                switch graphQLResponse {
                case .success(let list):
                    self.elements = list.elements
                    self.document = list.document
                    self.variables = list.variables
                    self.nextToken = list.nextToken
                    self.state = .loaded
                    completion(.success(()))
                case .failure(let graphQLError):
                    completion(.failure(.listOperation(
                                            "The AppSync response returned successfully with GraphQL errors.",
                                            "Check the underlying error for the failed GraphQL response.",
                                            graphQLError)))
                }
            case .failure(let apiError):
                completion(.failure(.listOperation("The AppSync request failed",
                                                   "Check the underlying `APIError`",
                                                   apiError)))
            }
        }
    }

    // This method will return a request to retrieve `ModelType` based on its `associatedField` by the `associatedId`.
    // For example, if this is a Comment, which belongs to Post, the associatedField is the Post and the associatedId is
    // the belonging to Post's ID. The request constructed will leverage existing GraphQLRequest document builders
    // and decorators to create
    // - A GraphQL `query` operation
    // - A `list` type query operation
    // - A filter on the associated field with `associatedId`
    func constructGraphQLRequestForFirstPage() -> GraphQLRequest<AppSyncList<ModelType>> {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelType.schema, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))

        if let associatedField = associatedField {
            var fieldName = associatedField.name
            if case let .belongsTo(_, targetName) = associatedField.association {
                // use the default service generated field name if the targetName does not exist
                fieldName = targetName ?? ModelType.modelName.camelCased() + associatedField.name.pascalCased() + "Id"
            }
            let predicate: QueryPredicate = field(fieldName) == associatedId
            documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter))
        }

        documentBuilder.add(decorator: PaginationDecorator())
        let document = documentBuilder.build()
        return GraphQLRequest<AppSyncList<ModelType>>(document: document.stringValue,
                                                      variables: document.variables,
                                                      responseType: AppSyncList<ModelType>.self,
                                                      decodePath: document.name)
    }
}
