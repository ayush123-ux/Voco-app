import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

/// Utility for dispatching Apple VoiceOver announcements, haptics, and non-visual feedback
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
        guard !screenTitle.isEmpty else { return }
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

    /// Plays a subtle haptic feedback and audio cue for listening start
    public static func playListeningStartCue() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        AudioServicesPlaySystemSound(1113) // iOS standard dictation start chime
        #endif
    }

    /// Plays feedback when listening successfully stops / processes
    public static func playListeningStopCue() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        AudioServicesPlaySystemSound(1114) // iOS standard dictation stop chime
        #endif
    }

    /// Plays an error alert haptic and sound
    public static func playErrorCue() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
        AudioServicesPlaySystemSound(1053) // Standard alert tone
        #endif
    }

    /// Plays a success haptic
    public static func playSuccessCue() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }
}
