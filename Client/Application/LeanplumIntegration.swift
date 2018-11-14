/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AdSupport
import Shared
import Leanplum

private let LeanplumEnvironmentKey = "LeanplumEnvironment"
private let LeanplumAppIdKey = "LeanplumAppId"
private let LeanplumKeyKey = "LeanplumKey"

private enum LeanplumEnvironment: String {
    case development = "development"
    case production = "production"
}

enum LeanplumEventName: String {
    case firstRun = "First Run"
    case secondRun = "Second Run"
    case openedApp = "Opened App"
    case openedLogins = "Opened Login Manager"
    case openedBookmark = "Opened Bookmark"
    case openedNewTab = "Opened New Tab"
    case interactWithURLBar = "Interact With Search URL Area"
    case savedBookmark = "Saved Bookmark"
    case openedTelephoneLink = "Opened Telephone Link"
    case openedMailtoLink = "Opened Mailto Link"
    case downloadedImage = "Download Media - Saved Image"
    case closedPrivateTabsWhenLeavingPrivateBrowsing = "Closed Private Tabs When Leaving Private Browsing"
    case closedPrivateTabs = "Closed Private Tabs"
    case savedLoginAndPassword = "Saved Login and Password"
    case userTappedFocusPromoButton = "User Tapped Focus Promo Button"
    case focusPromoImpression = "Focus Promo Impression"
    case focusPromoTimeout = "Focus Promo Timed Out"
    case focusPromoTapDismiss = "Focus Promo was Dismissed By Tap"
}

private enum SupportedLocales: String {
    case US = "en_US"
    case DE = "de"
    case UK = "en_GB"
    case CA_EN = "en_CA"
    case AU = "en_AU"
    case TW = "zh_TW"
    case HK = "en_HK"
    case SG_EN = "en_SG"
}

private struct LeanplumSettings {
    var environment: LeanplumEnvironment
    var appId: String
    var key: String
}

class LeanplumIntegration {
    static let sharedInstance = LeanplumIntegration()

    // Setup

    private var profile: Profile?
    private var enabled: Bool = false
    
    func shouldSendToLP() -> Bool {
        return enabled && Leanplum.hasStarted()
    }

    func setup(profile: Profile) {
        self.profile = profile
    }
    
    func start() {
        if let userUsageSetting = self.profile?.prefs.boolForKey("settings.sendUsageData") {
            self.enabled = userUsageSetting
        }
        else {
            self.enabled = false
        }
        guard self.enabled else {
            return
        }
        
        guard SupportedLocales(rawValue: Locale.current.identifier) != nil else {
            return
        }

        if Leanplum.hasStarted() {
            Logger.browserLogger.error("LeanplumIntegration - Already initialized")
            return
        }

        guard let settings = getSettings() else {
            Logger.browserLogger.error("LeanplumIntegration - Could not load settings from Info.plist")
            return
        }

        switch settings.environment {
        case .development:
            Logger.browserLogger.info("LeanplumIntegration - Setting up for Development")
            Leanplum.setDeviceId(ASIdentifierManager.shared().advertisingIdentifier.uuidString)
            Leanplum.setAppId(settings.appId, withDevelopmentKey: settings.key)
        case .production:
            Logger.browserLogger.info("LeanplumIntegration - Setting up for Production")
            Leanplum.setAppId(settings.appId, withProductionKey: settings.key)
        }
        Leanplum.syncResourcesAsync(true)
        setupTemplateDictionary()

        var userAttributesDict = [AnyHashable: Any]()
        userAttributesDict["Focus Installed"] = "false"
        userAttributesDict["Klar Installed"] = "false"
        userAttributesDict["Alternate Mail Client Installed"] = "mailto:"

        if let focusURL = URL(string: "firefox-focus://"), UIApplication.shared.canOpenURL(focusURL) {
            userAttributesDict["Focus Installed"] = "true"
        }

        if let klarURL = URL(string: "firefox-klar://"), UIApplication.shared.canOpenURL(klarURL) {
            userAttributesDict["Klar Installed"] = "true"
        }

        if let mailtoScheme = self.profile?.prefs.stringForKey(PrefsKeys.KeyMailToOption), mailtoScheme != "mailto:" {
            userAttributesDict["Alternate Mail Client Installed"] = mailtoScheme
        }

        Leanplum.start(userAttributes: userAttributesDict)

        Leanplum.track(LeanplumEventName.openedApp.rawValue)
    }

    // Events

    func track(eventName: LeanplumEventName) {
        if shouldSendToLP() {
            Leanplum.track(eventName.rawValue)
        }
    }

    func track(eventName: LeanplumEventName, withParameters parameters: [String: AnyObject]) {
        if shouldSendToLP() {
            Leanplum.track(eventName.rawValue, withParameters: parameters)
        }
    }

    // States

    func advanceTo(state: String) {
        if shouldSendToLP() {
            Leanplum.advance(to: state)
        }
    }

    // Data Modeling

    func setupTemplateDictionary() {
        if shouldSendToLP() {
            LPVar.define("Template Dictionary", with: ["Template Text": "", "Button Text": "", "Deep Link": "", "Hex Color String": ""])
        }
    }

    func getTemplateDictionary() -> [String:String]? {
        if shouldSendToLP() {
            return Leanplum.object(forKeyPathComponents: ["Template Dictionary"]) as? [String : String]
        }
        return nil
    }

    func getBoolVariableFromServer(key: String) -> Bool? {
        if shouldSendToLP() {
            return Leanplum.object(forKeyPathComponents: [key]) as? Bool
        }
        return nil
    }

    // Utils
    
    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        if self.enabled {
            self.start()
        }
    }

    func shouldShowFocusUI() -> Bool {
        guard let shouldShowFocusUI = LeanplumIntegration.sharedInstance.getBoolVariableFromServer(key: "shouldShowFocusUI"), let focus = URL(string: "firefox-focus://"), let klar = URL(string: "firefox-klar://"), !UIApplication.shared.canOpenURL(focus) && !UIApplication.shared.canOpenURL(klar) && shouldShowFocusUI else {
            return false
        }
        return true
    }

    // Private

    private func getSettings() -> LeanplumSettings? {
        let bundle = Bundle.main
        guard let environmentString = bundle.object(forInfoDictionaryKey: LeanplumEnvironmentKey) as? String, let environment = LeanplumEnvironment(rawValue: environmentString), let appId = bundle.object(forInfoDictionaryKey: LeanplumAppIdKey) as? String, let key = bundle.object(forInfoDictionaryKey: LeanplumKeyKey) as? String else {
            return nil
        }
        return LeanplumSettings(environment: environment, appId: appId, key: key)
    }
}
