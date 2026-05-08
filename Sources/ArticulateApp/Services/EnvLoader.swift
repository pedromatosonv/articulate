import Foundation

enum EnvLoaderError: LocalizedError {
    case missingOpenAIAPIKey

    var errorDescription: String? {
        switch self {
        case .missingOpenAIAPIKey:
            return "OPENAI_API_KEY was not found in the process environment or .env.local."
        }
    }
}

enum EnvLoader {
    static func openAIAPIKey() throws -> String {
        if let value = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return value
        }

        for url in candidateEnvFiles() {
            if let value = readEnvValue(named: "OPENAI_API_KEY", from: url) {
                return value
            }
        }

        throw EnvLoaderError.missingOpenAIAPIKey
    }

    private static func candidateEnvFiles() -> [URL] {
        var roots: [URL] = [
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        ]

        if let bundleRoot = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent() as URL? {
            roots.append(bundleRoot)
        }

        if let resourceURL = Bundle.main.resourceURL {
            roots.append(resourceURL)
        }

        var candidates: [URL] = []
        var seen = Set<String>()

        for root in roots {
            var current = root.standardizedFileURL
            for _ in 0..<6 {
                let envURL = current.appendingPathComponent(".env.local")
                if !seen.contains(envURL.path) {
                    candidates.append(envURL)
                    seen.insert(envURL.path)
                }
                let parent = current.deletingLastPathComponent()
                if parent.path == current.path {
                    break
                }
                current = parent
            }
        }

        return candidates
    }

    private static func readEnvValue(named name: String, from url: URL) -> String? {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        for rawLine in contents.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#") else {
                continue
            }

            let parts = line.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2, parts[0].trimmingCharacters(in: .whitespaces) == name else {
                continue
            }

            let value = String(parts[1])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

            if !value.isEmpty {
                return value
            }
        }

        return nil
    }
}

