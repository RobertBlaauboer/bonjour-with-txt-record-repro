import SwiftUI

struct ContentView: View {
    @StateObject private var serviceBrowser = ServiceBrowser()

    var body: some View {
        NavigationView {
            List {
                if serviceBrowser.discoveredServices.isEmpty {
                    Text("No services found")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(serviceBrowser.discoveredServices) { service in
                        ServiceRow(service: service)
                    }
                }
            }
            .navigationTitle("Bonjour Services")
        }
    }
}

struct ServiceRow: View {
    let service: DiscoveredService

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(service.name)
                .font(.headline)
            Text("\(service.type).\(service.domain)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
