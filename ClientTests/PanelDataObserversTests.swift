/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest
@testable import Client

private class MockDataObserverDelegate: DataObserverDelegate {
    var delegateCalledCount = 0

    func didInvalidateDataSources() {
        delegateCalledCount += 1
    }
}

class PanelDataObserversTests: XCTestCase {
    func testActivityStreamDelegates() {
        let profile = MockProfile()
        let observer = ActivityStreamDataObserver(profile: profile)
        let delegate = MockDataObserverDelegate()
        observer.delegate = delegate

        NotificationCenter.default.post(name: NotificationFirefoxAccountChanged,
                                        object: nil)
        NotificationCenter.default.post(name: NotificationProfileDidFinishSyncing,
                                        object: nil)
        NotificationCenter.default.post(name: NotificationPrivateDataClearedHistory,
                                        object: nil)

        waitForCondition(timeout: 5) { delegate.delegateCalledCount == 3 }
    }
}
