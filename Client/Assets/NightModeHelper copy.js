/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
"use strict";

if (!window.__firefox__) {
  Object.defineProperty(window, '__firefox__', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: {}
  });
}

Object.defineProperty(window.__firefox__, 'NightMode', {
  enumerable: false,
  configurable: false,
  writable: false,
  value: { enabled: false }
});

var className = "__firefox__NightMode";

function initializeStyleSheet() {
  var nightCSS = 'html{-webkit-filter:brightness(110%) contrast(100%) !important;  -webkit-text-shadow:#fff 1px 0 0,#fff 0 1px 0,#fff -1px 0 0,#fff 0 -1px 0; } .box { position: relative; background-color: #8da6ff33; height: 200px; overflow: hidden; overflow-x: hidden; overflow-y: hidden; transform: matrix3d(0.687303, 0.722829, -0.0716384, 0, -0.463592, 0.512446, 0.722829, 0, 0.559193, -0.463592, 0.687303, 0, 0, 0, 0, 1);}body{background: none;width: 50%;height: 50%;}';
  var newCss = document.getElementById(className);
  if (!newCss) {
    var cssStyle = document.createElement("style");
    cssStyle.type = "text/css";
    cssStyle.id = className;
    cssStyle.appendChild(document.createTextNode(nightCSS));
    document.documentElement.appendChild(cssStyle);
  } else {
    newCss.innerHTML = nightCSS;
  }
}



Object.defineProperty(window.__firefox__.NightMode, 'setEnabled', {
  enumerable: false,
  configurable: false,
  writable: false,
  value: function(enabled) {
    if (enabled === window.__firefox__.NightMode.enabled) {
      return;
    }
    window.__firefox__.NightMode.enabled = enabled;
    if (enabled) {
      initializeStyleSheet();
    } else {
      var style = document.getElementById(className);
      if (style) {
        style.remove();
      }
    }
  }
});

window.addEventListener("DOMContentLoaded", function(event) {
  window.__firefox__.NightMode.setEnabled(window.__firefox__.NightMode.enabled);
});

})();
