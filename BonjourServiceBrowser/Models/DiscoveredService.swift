import Foundation
import Network

struct DiscoveredService: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: String
    let domain: String
    let endpoint: NWEndpoint?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DiscoveredService, rhs: DiscoveredService) -> Bool {
        lhs.id == rhs.id
    }
}
