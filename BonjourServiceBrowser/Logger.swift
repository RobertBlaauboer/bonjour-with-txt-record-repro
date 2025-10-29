import Foundation

class Logger {
    static let shared = Logger()

    private let logQueue = DispatchQueue(label: "com.example.BonjourServiceBrowser.logger", qos: .utility)
    private let dateFormatter: DateFormatter
    private let logFileURL: URL

    private init() {
        // Setup date formatter for timestamps
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        // Get log file URL in documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        logFileURL = documentsPath.appendingPathComponent("bonjour_service_browser.log")

        // Create log file if it doesn't exist
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }

        // Log initialization
        log("Logger initialized. Log file: \(logFileURL.path)")
    }

    func log(_ message: String, level: LogLevel = .info) {
        logQueue.async { [weak self] in
            guard let self = self else { return }

            let timestamp = self.dateFormatter.string(from: Date())
            let logEntry = "[\(timestamp)] [\(level.rawValue)] \(message)\n"

            // Print to console
            print(logEntry, terminator: "")

            // Write to file
            if let data = logEntry.data(using: .utf8) {
                if let fileHandle = try? FileHandle(forWritingTo: self.logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            }
        }
    }

    func getLogFilePath() -> String {
        return logFileURL.path
    }

    func clearLog() {
        logQueue.async { [weak self] in
            guard let self = self else { return }
            try? "".write(to: self.logFileURL, atomically: true, encoding: .utf8)
        }
    }
}

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}
