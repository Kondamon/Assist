//
//  BetaTester.swift
//  ASC
//
//  Created by Stefan Herold on 16.07.20.
//

import Foundation

struct BetaTester: Codable {
    var type: String
    var id: String
    var attributes: Attributes
    var relationships: Relationships
}

extension BetaTester {

    struct Attributes: Codable {
        var firstName: String
        var lastName: String
        var email: String
        var inviteType: InviteType
    }

    struct Relationships: Codable {
        var apps: Relation
        var betaGroups: Relation
        var builds: Relation
    }
}

extension Array where Element == BetaTester {

    func out(_ attribute: String?) {
        switch attribute {
        case "name": out(\.name)
        case "attributes": out(\.attributes)
        case "firstName": out(\.attributes.firstName)
        case "lastName": out(\.attributes.lastName)
        case "email": out(\.attributes.email)
        default: out(\.id)
        }
    }
}

extension BetaTester {

    func out(_ attribute: String?) {
        switch attribute {
        case "attributes": print( attributes )
        case "firstName": print( attributes.firstName )
        case "lastName": print( attributes.lastName )
        case "email": print( attributes.email )
        default: print( id )
        }
    }
}

extension BetaTester: Model {

    var name: String {
        var comps = PersonNameComponents()
        comps.givenName = attributes.firstName
        comps.familyName = attributes.lastName
        return PersonNameComponentsFormatter().string(from: comps)
    }
}
