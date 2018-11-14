/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared

struct NoImageModePrefsKey {
    static let NoImageModeButtonIsInMenu = PrefsKeys.KeyNoImageModeButtonIsInMenu
    static let NoImageModeStatus = PrefsKeys.KeyNoImageModeStatus
}

class NoImageModeHelper: TabHelper {
    fileprivate weak var tab: Tab?

    required init(tab: Tab) {
        self.tab = tab
        if let path = Bundle.main.path(forResource: "NoImageModeHelper", ofType: "js"), let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
            let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)
            tab.webView!.configuration.userContentController.addUserScript(userScript)
        }
    }

    static func name() -> String {
        return "NoImageMode"
    }

    func scriptMessageHandlerName() -> String? {
        return "NoImageMode"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // Do nothing.
    }

    static func isNoImageModeAvailable(_ state: AppState) -> Bool {
        return state.prefs.boolForKey(NoImageModePrefsKey.NoImageModeButtonIsInMenu) ?? AppConstants.MOZ_NO_IMAGE_MODE
    }

    static func isNoImageModeActivated(_ state: AppState) -> Bool {
        return state.prefs.boolForKey(NoImageModePrefsKey.NoImageModeStatus) ?? false
    }
}
