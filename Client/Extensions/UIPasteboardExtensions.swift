/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MobileCoreServices
import UIKit

extension UIPasteboard {

    func addImageWithData(_ data: Data, forURL url: URL) {
        let isGIF = UIImage.dataIsGIF(data)

        // Setting pasteboard.items allows us to set multiple representations for the same item.
        items = [[
            kUTTypeURL as String: url,
            imageTypeKey(isGIF): data
        ]]
    }

    fileprivate func imageTypeKey(_ isGIF: Bool) -> String {
        return (isGIF ? kUTTypeGIF : kUTTypePNG) as String
    }
    
    var copiedURL: URL? {
        if let string = UIPasteboard.general.string,
            let url = URL(string: string), url.isWebPage() {
            return url
        } else {
            return nil
        }
    }
}
