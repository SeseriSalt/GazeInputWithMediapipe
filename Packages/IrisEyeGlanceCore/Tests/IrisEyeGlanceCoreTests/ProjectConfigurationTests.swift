import Foundation
import Testing

/// Validates the application configuration that is not covered by the compiler:
/// the effective Info.plist (build settings + file), the privacy manifest and the
/// Xcode project build settings.
@Suite("Project configuration")
struct ProjectConfigurationTests {

    // MARK: Info.plist

    @Test("Camera usage description explains face tracking, not profile photos")
    func cameraUsageDescription() throws {
        let plist = try EffectiveInfoPlist()
        let description = try #require(plist.string("NSCameraUsageDescription"))
        #expect(!description.contains("プロフィール"))
        #expect(description.contains("顔") || description.lowercased().contains("face"))
        #expect(description.contains("視線") || description.lowercased().contains("eye"))
    }

    @Test("Required device capabilities target arm64 devices with a front camera")
    func requiredDeviceCapabilities() throws {
        let plist = try EffectiveInfoPlist()
        let capabilities = try #require(plist.stringList("UIRequiredDeviceCapabilities"))
        #expect(capabilities.contains("arm64"))
        #expect(capabilities.contains("front-facing-camera"))
        #expect(!capabilities.contains("armv7"))
    }

    @Test("Interface orientation is locked to portrait")
    func portraitOnly() throws {
        let plist = try EffectiveInfoPlist()
        let orientations = try #require(plist.stringList("UISupportedInterfaceOrientations"))
        #expect(orientations == ["UIInterfaceOrientationPortrait"])
        #expect(!plist.contains("UISupportedInterfaceOrientations~ipad"))
        #expect(plist.buildSettingKeys["UISupportedInterfaceOrientations_iPad"] == nil)
        #expect(plist.buildSettingKeys["UISupportedInterfaceOrientations_iPhone"] == nil)
    }

    @Test("Export compliance is declared so TestFlight does not prompt")
    func exportCompliance() throws {
        let plist = try EffectiveInfoPlist()
        #expect(plist.bool("ITSAppUsesNonExemptEncryption") == false)
    }

    @Test("CSV files stay reachable through the Files app")
    func fileSharing() throws {
        let plist = try EffectiveInfoPlist()
        #expect(plist.bool("UIFileSharingEnabled") == true)
        #expect(plist.bool("LSSupportsOpeningDocumentsInPlace") == true)
    }

    @Test("No key is defined both in Info.plist and as a build setting")
    func noDuplicatedKeys() throws {
        let plist = try EffectiveInfoPlist()
        #expect(plist.duplicatedKeys.isEmpty, "Duplicated: \(plist.duplicatedKeys.sorted())")
    }

    @Test("UI is built in code: only the launch storyboard remains")
    func storyboardKeys() throws {
        let plist = try EffectiveInfoPlist()
        #expect(plist.string("UIMainStoryboardFile") == nil)
        #expect(plist.string("UILaunchStoryboardName") == "LaunchScreen")
        let manifest = try #require(plist.fileKeys["UIApplicationSceneManifest"] as? [String: Any])
        let configurations = try #require(manifest["UISceneConfigurations"] as? [String: Any])
        let roles = try #require(configurations["UIWindowSceneSessionRoleApplication"] as? [[String: Any]])
        #expect(roles.allSatisfy { $0["UISceneStoryboardFile"] == nil })
        #expect(!FileManager.default.fileExists(atPath: RepositoryPaths.appSources.appendingPathComponent("Base.lproj/Main.storyboard").path))
    }

    @Test("Panel and row-hint PNG assets are no longer needed")
    func noPanelImages() throws {
        let assets = RepositoryPaths.appSources.appendingPathComponent("Assets.xcassets")
        let contents = try FileManager.default.contentsOfDirectory(atPath: assets.path)
        let leftovers = contents.filter { $0.hasPrefix("design") || $0.hasPrefix("row") || $0 == "apple.imageset" }
        #expect(leftovers.isEmpty, "Unused image sets: \(leftovers)")
    }

    // MARK: Privacy manifest

    @Test("Privacy manifest declares the UserDefaults API reason")
    func privacyManifest() throws {
        let manifest = try RepositoryPaths.plist(at: RepositoryPaths.privacyManifest)
        let apiTypes = try #require(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let userDefaults = try #require(apiTypes.first {
            $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults"
        })
        let reasons = try #require(userDefaults["NSPrivacyAccessedAPITypeReasons"] as? [String])
        #expect(reasons.contains("CA92.1"))
        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
    }

    // MARK: Xcode project

    @Test("Deployment target and device family match the supported hardware")
    func deploymentTarget() throws {
        let project = try RepositoryPaths.projectSource()
        #expect(!project.contains("IPHONEOS_DEPLOYMENT_TARGET = 14.0"))
        #expect(project.contains("IPHONEOS_DEPLOYMENT_TARGET = 17.0"))
        #expect(project.contains("TARGETED_DEVICE_FAMILY = 1;"))
        #expect(!project.contains("TARGETED_DEVICE_FAMILY = \"1,2\""))
    }

    @Test("Strict concurrency checking is enabled")
    func strictConcurrency() throws {
        let project = try RepositoryPaths.projectSource()
        #expect(project.contains("SWIFT_STRICT_CONCURRENCY = complete;"))
    }

    @Test("Privacy manifest is bundled as an app resource")
    func privacyManifestIsInProject() throws {
        let project = try RepositoryPaths.projectSource()
        #expect(project.contains("PrivacyInfo.xcprivacy in Resources"))
    }

    @Test("Core package is linked into the app target")
    func corePackageIsLinked() throws {
        let project = try RepositoryPaths.projectSource()
        #expect(project.contains("XCLocalSwiftPackageReference"))
        #expect(project.contains("productName = IrisEyeGlanceCore"))
    }
}
