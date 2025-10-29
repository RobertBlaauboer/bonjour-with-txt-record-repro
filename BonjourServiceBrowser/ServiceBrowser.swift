import Foundation
import Network
import Combine

class ServiceBrowser: ObservableObject {
    @Published var discoveredServices: [DiscoveredService] = []

    private var browser: NWBrowser?
    private let serviceType = "_test._tcp"

    init() {
        startBrowsing()
    }

    func startBrowsing() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: .bonjourWithTXTRecord(type: serviceType, domain: nil), using: parameters)

        browser?.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .ready:
                print("Browser is ready")
            case .failed(let error):
                print("Browser failed with error: \(error)")
            case .cancelled:
                print("Browser cancelled")
            default:
                break
            }
        }

        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            DispatchQueue.main.async {
                self?.handleBrowseResults(results: results, changes: changes)
            }
        }

        browser?.start(queue: .global(qos: .userInitiated))
    }

    private func handleBrowseResults(results: Set<NWBrowser.Result>, changes: Set<NWBrowser.Result.Change>) {
        for change in changes {
            switch change {
            case .added(let result):
                addService(from: result)
            case .removed(let result):
                removeService(from: result)
            case .changed(_, let new, _):
                updateService(from: new)
            case .identical:
                break
            @unknown default:
                break
            }
        }
    }

    private func addService(from result: NWBrowser.Result) {
        guard case .service(let name, let type, let domain, _) = result.endpoint else {
            return
        }

        let service = DiscoveredService(
            name: name,
            type: type,
            domain: domain,
            endpoint: result.endpoint
        )

        if !discoveredServices.contains(where: { $0.name == name && $0.domain == domain }) {
            discoveredServices.append(service)
            print("Service added: \(name)")
        }
    }

    private func removeService(from result: NWBrowser.Result) {
        guard case .service(let name, _, let domain, _) = result.endpoint else {
            return
        }

        discoveredServices.removeAll { $0.name == name && $0.domain == domain }
        print("Service removed: \(name)")
    }

    private func updateService(from result: NWBrowser.Result) {
        guard case .service(let name, let type, let domain, _) = result.endpoint else {
            return
        }

        if let index = discoveredServices.firstIndex(where: { $0.name == name && $0.domain == domain }) {
            discoveredServices[index] = DiscoveredService(
                name: name,
                type: type,
                domain: domain,
                endpoint: result.endpoint
            )
            print("Service updated: \(name)")
        }
    }

    deinit {
        browser?.cancel()
    }
}
