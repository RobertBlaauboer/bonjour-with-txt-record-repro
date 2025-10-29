import SwiftUI

@main
struct BonjourServiceBrowserApp: App {
    init() {
        Logger.shared.log("=== Bonjour Service Browser App Starting ===", level: .info)
        Logger.shared.log("Log file location: \(Logger.shared.getLogFilePath())", level: .info)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
