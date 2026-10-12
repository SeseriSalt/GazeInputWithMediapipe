import Foundation

/// Locates files in the repository relative to this test source file, so that
/// configuration files (Info.plist, PrivacyInfo.xcprivacy) can be validated by `swift test`.
enum RepositoryPaths {
    /// Repository root: `<root>/Packages/IrisEyeGlanceCore/Tests/IrisEyeGlanceCoreTests/Support/RepositoryPaths.swift`
    static var root: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // RepositoryPaths.swift
            .deletingLastPathComponent() // Support
            .deletingLastPathComponent() // IrisEyeGlanceCoreTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // IrisEyeGlanceCore
            .deletingLastPathComponent() // Packages
    }

    static var appSources: URL { root.appendingPathComponent("IrisEyeGlance") }
    static var infoPlist: URL { appSources.appendingPathComponent("Info.plist") }
    static var privacyManifest: URL { appSources.appendingPathComponent("PrivacyInfo.xcprivacy") }
    static var projectFile: URL {
        root.appendingPathComponent("IrisEyeGlance.xcodeproj").appendingPathComponent("project.pbxproj")
    }

    static func plist(at url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        let object = try PropertyListSerialization.propertyList(from: data, format: nil)
        guard let dictionary = object as? [String: Any] else {
            throw NSError(domain: "RepositoryPaths", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not a dictionary plist: \(url.path)"])
        }
        return dictionary
    }

    static func projectSource() throws -> String {
        try String(contentsOf: projectFile, encoding: .utf8)
    }
}

/// The Info.plist as Xcode will generate it: `INFOPLIST_KEY_*` build settings merged with
/// the keys that stay in `Info.plist`. Xcode migrates plain keys into build settings
/// automatically, so tests must look at the merged result rather than at one file.
struct EffectiveInfoPlist {
    /// Values from `INFOPLIST_KEY_*` build settings, keyed by plist key.
    let buildSettingKeys: [String: String]
    /// Keys that remain in the Info.plist file.
    let fileKeys: [String: Any]

    init() throws {
        fileKeys = try RepositoryPaths.plist(at: RepositoryPaths.infoPlist)
        buildSettingKeys = try EffectiveInfoPlist.parseBuildSettingKeys(try RepositoryPaths.projectSource())
    }

    /// Keys defined in both places; Xcode would silently prefer the build setting.
    var duplicatedKeys: Set<String> {
        Set(buildSettingKeys.keys).intersection(fileKeys.keys)
    }

    func string(_ key: String) -> String? {
        if let value = buildSettingKeys[key] { return value }
        return fileKeys[key] as? String
    }

    func bool(_ key: String) -> Bool? {
        if let value = buildSettingKeys[key] {
            switch value.uppercased() {
            case "YES", "TRUE", "1": return true
            case "NO", "FALSE", "0": return false
            default: return nil
            }
        }
        return fileKeys[key] as? Bool
    }

    /// Array-valued keys are written as space separated strings in build settings.
    func stringList(_ key: String) -> [String]? {
        if let value = buildSettingKeys[key] {
            return value.split(separator: " ").map(String.init)
        }
        return fileKeys[key] as? [String]
    }

    func contains(_ key: String) -> Bool {
        buildSettingKeys[key] != nil || fileKeys[key] != nil
    }

    /// Parses `INFOPLIST_KEY_<key> = <value>;` lines. Values must agree across configurations.
    private static func parseBuildSettingKeys(_ source: String) throws -> [String: String] {
        var result: [String: String] = [:]
        let pattern = #"INFOPLIST_KEY_([A-Za-z0-9_]+)\s*=\s*(.*?);\s*$"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        let range = NSRange(source.startIndex..., in: source)
        for match in regex.matches(in: source, range: range) {
            guard let keyRange = Range(match.range(at: 1), in: source),
                  let valueRange = Range(match.range(at: 2), in: source) else { continue }
            let key = String(source[keyRange])
            var value = String(source[valueRange]).trimmingCharacters(in: .whitespaces)
            if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
                value = String(value.dropFirst().dropLast())
            }
            if let existing = result[key], existing != value {
                throw NSError(domain: "EffectiveInfoPlist", code: 2, userInfo: [NSLocalizedDescriptionKey: "INFOPLIST_KEY_\(key) differs between configurations: \(existing) vs \(value)"])
            }
            result[key] = value
        }
        return result
    }
}
