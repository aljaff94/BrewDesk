import Foundation

struct BrewInfoResponse: Codable, Sendable {
    let formulae: [Formula]
    let casks: [Cask]
}

struct BrewOutdatedResponse: Codable, Sendable {
    let formulae: [OutdatedFormula]
    let casks: [OutdatedCask]
}
