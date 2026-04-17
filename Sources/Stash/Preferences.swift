import Foundation
import SwiftUI
import Combine

final class Preferences: ObservableObject {
    static let shared = Preferences()

    @AppStorage("capacity") var capacity: Int = 5
    @AppStorage("enableText") var enableText: Bool = true
    @AppStorage("enableImages") var enableImages: Bool = true
    @AppStorage("enableFiles") var enableFiles: Bool = true
    @AppStorage("persistHistory") var persistHistory: Bool = false
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false

    private init() {}
}
