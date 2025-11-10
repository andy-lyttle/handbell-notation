/*
 * SPDX-License-Identifier: GPL-3.0-only
 * MuseScore-Studio-CLA-applies
 *
 * Shared code to implement simple dialog boxes, compatible with MuseScore 3 and 4.
 * Copyright (C) 2025 Andy Lyttle
 *
 **********************************************************************************
 *
 * Usage:
 * 
 * import QtQuick 2.2
 * import MuseScore 3.0
 * import QtQuick.Controls 2.2
 * import "DialogBox.js" as DialogBox
 *
 * MuseScore {
 *       id: msParent
 *       ...
 * }
 * 
 * DialogBox.showInfo("Text goes here.", function(btn) {
 *       if(btn) {
 *             console.log("Successfully clicked " + btn + " button");
 *       } else {
 *             console.log("Dialog box closed without clicking any button");
 *       }
 *       doTheNextThing();
 * })
 * 
 * DialogBox.showWarning("Text goes here.");
 * DialogBox.showError("Text goes here.")
 *
 * // Note that execution continues immediately after showing a dialog box;
 * // if you want to wait for the user to click the button before proceeding,
 * // showing the dialog box should be the last thing your script does, and
 * // you must pass a callback function to do whatever you want to happen next. 
 * // If no callback function is passed, calls quit() to terminate the plugin.
 * // If you don't want that, you can pass an empty callback function.
 *
 **********************************************************************************
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

function showDialog(title, icon, msg, callback) {
      // This is ugly, but using a multi-line quote with backticks doesn't work
      var qmlText = "";
      qmlText += 'import QtQuick 2.2' + "\n";
      qmlText += 'import MuseScore 3.0' + "\n";
      qmlText += 'import QtQuick.Controls 2.2' + "\n";
      qmlText += 'ApplicationWindow {' + "\n";
      qmlText += '      visible: false' + "\n";
      qmlText += '      flags: Qt.Dialog | Qt.WindowStaysOnTopHint' + "\n";
      qmlText += '      width: 410' + "\n";
      qmlText += '      height: 160' + "\n";
      qmlText += '      property var selection: undefined' + "\n";
      qmlText += '      property var callbackFunction: undefined' + "\n";
      qmlText += '      property var closeHandler: undefined' + "\n";
      qmlText += '      onClosing: closeHandler()' + "\n";
      qmlText += '      Label {' + "\n";
      qmlText += '            id: dialogIcon' + "\n";
      qmlText += '            width: 84' + "\n";
      qmlText += '            font.pointSize: 72' + "\n";
      qmlText += '            horizontalAlignment: Text.AlignHCenter' + "\n";
      qmlText += '            anchors {' + "\n";
      qmlText += '                  top: parent.top' + "\n";
      qmlText += '                  left: parent.left' + "\n";
      qmlText += '                  margins: 14' + "\n";
      qmlText += '            }' + "\n";
      qmlText += '      }' + "\n";
      qmlText += '      Label {' + "\n";
      qmlText += '            id: dialogText' + "\n";
      qmlText += '            wrapMode: Text.WordWrap' + "\n";
      qmlText += '            width: 280' + "\n";
      qmlText += '            font.pointSize: 16' + "\n";
      qmlText += '            anchors {' + "\n";
      qmlText += '                  top: parent.top' + "\n";
      qmlText += '                  right: parent.right' + "\n";
      qmlText += '                  margins: 20' + "\n";
      qmlText += '            }' + "\n";
      qmlText += '      }' + "\n";
      qmlText += '      Button {' + "\n";
      qmlText += '            id: dialogButton' + "\n";
      qmlText += '            text: "Ok"' + "\n";
      qmlText += '            anchors {' + "\n";
      qmlText += '                  right: parent.right' + "\n";
      qmlText += '                  bottom: parent.bottom' + "\n";
      qmlText += '                  margins: 14' + "\n";
      qmlText += '            }' + "\n";
      qmlText += '            property var clickHandler: undefined' + "\n";
      qmlText += '            onClicked: clickHandler(text)' + "\n";
      qmlText += '      }' + "\n";
      qmlText += '      property alias dialogIcon: dialogIcon' + "\n";
      qmlText += '      property alias dialogText: dialogText' + "\n";
      qmlText += '      property alias dialogButton: dialogButton' + "\n";
      qmlText += '}' + "\n";

      // Use the above text blob to create our QML objects.  The ApplicationWindow is
      // returned.
      var appwin = Qt.createQmlObject(qmlText, msParent, "DialogBox.js");
      
      // Set some dynamic properties based on the parameters we were passed
      appwin.title = title;
      appwin.dialogIcon.text = icon;
      appwin.dialogText.text = msg;
      appwin.callbackFunction = callback;
      
      // Set the window height dynamically to fit all the text, unless there's a huge
      // amount of text, in which case we limit the height of the window to make sure
      // it fits on the screen.
      if(appwin.dialogText.height > 90) {
            appwin.height = Math.min(600, 90 + appwin.dialogText.height);
      }
      
      // Called when clicking the Ok button.  Instead of calling the callback
      // function here, we set appwin,selection so we know what button was clicked,
      // then simply close the window and let the onClosing function do the next thing.
      appwin.dialogButton.clickHandler = function() {
            appwin.selection = appwin.dialogButton.text;
            appwin.close();
      };

      // Called when the window is closed, either by clicking the close box in
      // the titlebar or by clicking the Ok button as expected
      appwin.closeHandler = function() {
            var title = appwin.title;
            var btn = appwin.selection; // label of the button that was clicked, if any
            var callbackFunction = appwin.callbackFunction; // what to do next, otherwise quit
            appwin.destroy(); // don't need our dialog box anymore
            
            if(callbackFunction) {
                  callbackFunction(btn);
            } else {
                  // Handle MuseScore 3.x and 4.x
                  (typeof(quit) === 'undefined' ? Qt.quit : quit)();
            }
      };
      
      // Everything is set up, so finally we show the window
      appwin.show();
      
      // Sometimes MuseScore 3 doesn't focus the window, so do that manually
      appwin.raise();
      appwin.requestActivate();
}
function showError(msg, callback) {
      showDialog("Error", "\uD83D\uDED1", msg, callback);
}
function showWarning(msg, callback) {
      showDialog("Warning", "\u26A0\uFE0F", msg, callback);
}
function showInfo(msg, callback) {
      showDialog("Information", "\u2139\uFE0F", msg, callback);
}
