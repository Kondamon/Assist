//
//  Network+Requests.swift
//  ASC
//
//  Created by Stefan Herold on 27.05.20.
//

import Foundation
import Core

struct ASCService {

    static let network = Network()

    // MARK: - BetaGroups

    static func readBetaGroups() throws -> [Group] {

        let apps = try readApps()
        var groups: [Group] = []

        let semaphore = DispatchSemaphore(value: 0)
        let betaGroupLinks = apps.map { $0[keyPath: \App.relationships.betaGroups.links.related] }
        let scheduledRequests = betaGroupLinks.count
        var finishedRequests = 0
        var error: Error?

        for url in betaGroupLinks {
            try network.request(resource: AscResource.read(url: url)) { (result: RequestResult<[Group]>) in
                switch result {
                case let .success(result):
                    groups += result
                case let .failure(err):
                    error = err
                    semaphore.signal()
                    return
                }
                finishedRequests += 1

                if finishedRequests == scheduledRequests {
                    semaphore.signal()
                }
            }
        }
        semaphore.wait()

        if let error = error {
            throw error
        }
        return groups
    }

    // MARK: - Apps

    static func readApps() throws -> [App] {

        let result: RequestResult<[App]> = try Self.network.syncRequest(resource: AscResource.readApps)

        switch result {
        case let .success(result): return result
        case let .failure(error): throw error
        }
    }

    // MARK: - BetaTester

    static func listBetaTester(email: String?,
                              firstName: String?,
                              lastName: String?) throws -> [BetaTester] {

        let result: RequestResult<[BetaTester]> = try Self.network.syncRequest(resource: AscResource.listBetaTester(email: email,
                                                                                                                    firstName: firstName,
                                                                                                                    lastName: lastName))

        switch result {
        case let .success(result): return result
        case let .failure(error): throw error
        }
    }

    static func addBetaTester(email: String,
                              firstName: String,
                              lastName: String,
                              groupId: String) throws -> BetaTester {

        let result: RequestResult<BetaTester> = try Self.network.syncRequest(resource: AscResource.addBetaTester(email: email,
                                                                                                                 firstName: firstName,
                                                                                                                 lastName: lastName,
                                                                                                                 groupId: groupId))

        switch result {
        case let .success(result): return result
        case let .failure(error): throw error
        }
    }

    static func deleteBetaTester(email: String, groupId: String) throws {

        guard let foundTester = try listBetaTester(email: email, firstName: nil, lastName: nil).first else {
            return
        }

        let result: RequestResult<EmptyResponse> = try Self.network.syncRequest(resource: AscResource.deleteBetaTester(id: foundTester.id))

        switch result {
        case .success: break
        case let .failure(error): throw error
        }
    }
}

extension ASCService: Service {

    func jsonDecode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {

        let dataResult = Result {
            try Json.decoder.decode(DataWrapper<T>.self, from: data)
        }.map {
            $0.object
        }

        guard (try? dataResult.get()) != nil else {
            // Decode model directly
            return try Json.decoder.decode(T.self, from: data)
        }

        // Extract data wrapped model OR throw the error from decoding it
        return try dataResult.get()
    }
}
