/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class URIFixup {
    static func getURL(_ entry: String) -> URL? {
        let trimmed = entry.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard let escaped = trimmed.addingPercentEncoding(withAllowedCharacters: CharacterSet.URLAllowedCharacterSet()) else {
            return nil
        }

        // Then check if the URL includes a scheme. This will handle
        // all valid requests starting with "http://", "about:", etc.
        // However, we ensure that the scheme is one that is listed in
        // the official URI scheme list, so that other such search phrases
        // like "filetype:" are recognised as searches rather than URLs.
        if let url = punycodedURL(escaped), url.schemeIsValid {
            return url
        }

        // If there's no scheme, we're going to prepend "http://". First,
        // make sure there's at least one "." in the host. This means
        // we'll allow single-word searches (e.g., "foo") at the expense
        // of breaking single-word hosts without a scheme (e.g., "localhost").
        if trimmed.range(of: ".") == nil {
            return nil
        }

        if trimmed.range(of: " ") != nil {
            return nil
        }

        // If there is a ".", prepend "http://" and try again. Since this
        // is strictly an "http://" URL, we also require a host.
        if let url = punycodedURL("http://\(escaped)"), url.host != nil {
            return url
        }

        return nil
    }

    static func punycodedURL(_ string: String) -> URL? {
        var components = URLComponents(string: string)
        components?.host = AppConstants.MOZ_PUNYCODE ? components?.host?.utf8HostToAscii() : components?.host
        return components?.url
    }
}
