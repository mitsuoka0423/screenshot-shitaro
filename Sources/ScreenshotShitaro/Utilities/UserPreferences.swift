import Foundation

final class UserPreferences {
    static let shared = UserPreferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hotkeyEnabled = "hotkeyEnabled"
        static let watchDesktop = "watchDesktop"
        static let watchPicturesScreenshots = "watchPicturesScreenshots"
        static let launchAtLogin = "launchAtLogin"
    }

    private init() {
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.hotkeyEnabled: true,
            Keys.watchDesktop: true,
            Keys.watchPicturesScreenshots: true,
            Keys.launchAtLogin: false
        ])
    }

    var isHotkeyEnabled: Bool {
        get { defaults.bool(forKey: Keys.hotkeyEnabled) }
        set { defaults.set(newValue, forKey: Keys.hotkeyEnabled) }
    }

    var watchesDesktop: Bool {
        get { defaults.bool(forKey: Keys.watchDesktop) }
        set { defaults.set(newValue, forKey: Keys.watchDesktop) }
    }

    var watchesPicturesScreenshots: Bool {
        get { defaults.bool(forKey: Keys.watchPicturesScreenshots) }
        set { defaults.set(newValue, forKey: Keys.watchPicturesScreenshots) }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set { defaults.set(newValue, forKey: Keys.launchAtLogin) }
    }
}
