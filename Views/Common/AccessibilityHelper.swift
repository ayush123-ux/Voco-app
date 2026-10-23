import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Utility for dispatching Apple VoiceOver announcements and accessibility notifications
public enum AccessibilityHelper {
    public static private(set) var lastAnnouncement: String = ""

    /// Dispatches an immediate spoken announcement to Apple VoiceOver
    public static func announce(_ message: String) {
        guard !message.isEmpty else { return }
        lastAnnouncement = message

        #if os(iOS)
        if #available(iOS 17.0, *) {
            AccessibilityNotification.Announcement(message).post()
        } else {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
        #endif
    }

    /// Announces a screen transition to Apple VoiceOver
    public static func announceScreenChange(_ screenTitle: String) {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            AccessibilityNotification.ScreenChanged().post()
        } else {
            UIAccessibility.post(notification: .screenChanged, argument: screenTitle)
        }
        #endif
    }

    /// Checks if VoiceOver is currently running
    public static var isVoiceOverRunning: Bool {
        #if os(iOS)
        return UIAccessibility.isVoiceOverRunning
        #else
        return false
        #endif
    }
}
