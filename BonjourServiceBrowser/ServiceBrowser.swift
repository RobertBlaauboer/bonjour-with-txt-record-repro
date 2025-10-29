import Foundation
import Network
import Combine

class ServiceBrowser: ObservableObject {
    @Published var discoveredServices: [DiscoveredService] = []

    private var browser: NWBrowser?
    private let serviceType = "_test._tcp"

    init() {
        Logger.shared.log("ServiceBrowser initialized")
        startBrowsing()
    }

    func startBrowsing() {
        Logger.shared.log("Starting Bonjour service browsing for type: \(serviceType)")

        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        let browserTypeEnv = ProcessInfo.processInfo.environment["BROWSER_TYPE"] ?? "bonjourWithTXTRecord"
        let useBonjourWithTXTRecord = (browserTypeEnv == "bonjourWithTXTRecord")

        let descriptor: NWBrowser.Descriptor
        if useBonjourWithTXTRecord {
            descriptor = .bonjourWithTXTRecord(type: serviceType, domain: nil)
            Logger.shared.log("Using .bonjourWithTXTRecord", level: .info)
        } else {
            descriptor = .bonjour(type: serviceType, domain: nil)
            Logger.shared.log("Using .bonjour", level: .info)
        }

        browser = NWBrowser(for: descriptor, using: parameters)

        browser?.stateUpdateHandler = { [weak self] newState in
            guard let self = self else { return }
            switch newState {
            case .ready:
                Logger.shared.log("Browser is ready", level: .info)
            case .failed(let error):
                Logger.shared.log("Browser failed with error: \(error)", level: .error)
            case .cancelled:
                Logger.shared.log("Browser cancelled", level: .warning)
            case .waiting(let error):
                Logger.shared.log("Browser waiting: \(error)", level: .warning)
            case .setup:
                Logger.shared.log("Browser setup", level: .debug)
            @unknown default:
                Logger.shared.log("Browser unknown state", level: .warning)
            }
        }

        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            Logger.shared.log("Browse results changed. Total results: \(results.count), Changes: \(changes.count)", level: .debug)
            DispatchQueue.main.async {
                self?.handleBrowseResults(results: results, changes: changes)
            }
        }

        browser?.start(queue: .global(qos: .userInitiated))
        Logger.shared.log("Browser started on background queue")
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
            Logger.shared.log("addService: endpoint is not a service", level: .warning)
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
            Logger.shared.log("Service added: \(name) (type: \(type), domain: \(domain))", level: .info)
        } else {
            Logger.shared.log("Service already exists: \(name)", level: .debug)
        }
    }

    private func removeService(from result: NWBrowser.Result) {
        guard case .service(let name, _, let domain, _) = result.endpoint else {
            Logger.shared.log("removeService: endpoint is not a service", level: .warning)
            return
        }

        let countBefore = discoveredServices.count
        discoveredServices.removeAll { $0.name == name && $0.domain == domain }
        let countAfter = discoveredServices.count

        if countBefore > countAfter {
            Logger.shared.log("Service removed: \(name) (domain: \(domain))", level: .info)
        } else {
            Logger.shared.log("Attempted to remove non-existent service: \(name)", level: .debug)
        }
    }

    private func updateService(from result: NWBrowser.Result) {
        guard case .service(let name, let type, let domain, _) = result.endpoint else {
            Logger.shared.log("updateService: endpoint is not a service", level: .warning)
            return
        }

        if let index = discoveredServices.firstIndex(where: { $0.name == name && $0.domain == domain }) {
            discoveredServices[index] = DiscoveredService(
                name: name,
                type: type,
                domain: domain,
                endpoint: result.endpoint
            )
            Logger.shared.log("Service updated: \(name) (type: \(type), domain: \(domain))", level: .info)
        } else {
            Logger.shared.log("Attempted to update non-existent service: \(name)", level: .debug)
        }
    }

    deinit {
        Logger.shared.log("ServiceBrowser deinitialized, cancelling browser")
        browser?.cancel()
    }
}
