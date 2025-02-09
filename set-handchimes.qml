/*
 * SPDX-License-Identifier: GPL-3.0-only
 * MuseScore-Studio-CLA-applies
 *
 * Handbell Notation plugins
 * Copyright (C) 2025 Andy Lyttle
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

import QtQuick 2.2
import MuseScore 3.0
import QtQuick.Controls 2.2

MuseScore {
      version:  "1.0"
      description: qsTr("Sets the selected notes to use red diamond noteheads. Does not affect playback.")
      menuPath: "Plugins.Handbell Notation.Set Selected Notes to Handchimes" // Ignored in MuseScore 4

      // These special comments are parsed by MuseScore 4.4, but ignored by older versions:
      //4.4 title: "Set Selected Notes to Handchimes"
      //4.4 thumbnailName: "set-handchimes.png"
      //4.4 categoryCode: "composing-arranging-tools"
      
      // The same thing for MuseScore 4.0-4.3, ignored by 4.4:
      Component.onCompleted: {
            if (mscoreMajorVersion == 4 && mscoreMinorVersion <= 3) {
                  title = "Set Selected Notes to Handchimes";
                  thumbnailName = "set-handchimes.png";
                  categoryCode = "composing-arranging-tools";
            }
      }

      // BEGIN: Set up dialog box
      ApplicationWindow {
            id: dialogBox
            visible: false
            flags: Qt.Dialog | Qt.WindowStaysOnTopHint
            width: 410
            height: 160
            property var text: ""
            property var icon: ""
            Label {
                  text: dialogBox.icon
                  width: 84;
                  font.pointSize: 72
                  horizontalAlignment: Text.AlignHCenter
                  anchors {
                        top: parent.top
                        left: parent.left
                        margins: 14
                  }
            }
            Label {
                  id: dialogText
                  text: dialogBox.text
                  wrapMode: Text.WordWrap
                  width: 280
                  font.pointSize: 16
                  anchors {
                        top: parent.top
                        right: parent.right
                        margins: 20
                  }
            }
            Button {
                  text: "Ok"
                  anchors {
                        right: parent.right
                        bottom: parent.bottom
                        margins: 14
                  }
                  onClicked: closeDialog()
            }
      }
      function closeDialog() {
            dialogBox.close();
            if(bellsUsedWindow.visible) {
                  // Closing the dialog causes the bellsUsedWindow to move behind
                  // the MuseScore window, so we need to bring it back to the front and give it focus
                  bellsUsedWindow.raise();
                  bellsUsedWindow.requestActivate();
            }
      }
      function showDialog(title, icon, msg) {
            dialogBox.title = title;
            dialogBox.icon = icon;
            dialogBox.text = msg;
            if(dialogText.height > 90) {
                  dialogBox.height = Math.min(600, 90 + dialogText.height);
            }
            dialogBox.visible = true;
      }
      function showError(msg) {
            showDialog("Error", "\uD83D\uDED1", msg);
      }
      function showWarning(msg) {
            showDialog("Warning", "\u26A0\uFE0F", msg);
      }
      function showInfo(msg) {
            showDialog("Information", "\u2139\uFE0F", msg);
      }
      // END: Set up dialog box

      // BEGIN: Set up color picker
      property string color_RED     : "#ff0000"
      property string color_DARKRED : "#a00000"
      property string color_BLACK   : "#000000"
      ApplicationWindow {
            id: colorWindow
            title: "Select Handchime Color"
            width: 400
            height: 300
            visible: false
            onClosing: colorPickerClosed();
            Label {
                  text: "Select your preferred color for handchimes:"
                  font.pointSize: 16
                  anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                        margins: 10
                  }
            }
      
            Label {
                  text: "Best for printing:"
                  font.pointSize: 16
                  anchors {
                        top: parent.top
                        left: parent.left
                        topMargin: 50
                        leftMargin: 10
                  }
            }
            Button {
                  background: Rectangle {
                        color: color_RED
                        border {
                              width: 2
                              color: "black"
                        }
                  }
                  width: 80
                  height: 40
                  anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: 40
                        rightMargin: 10
                  }
                  onClicked: selectColor(background.color)
            }
            Label {
                  text: "Better on screen:"
                  font.pointSize: 16
                  anchors {
                        top: parent.top
                        left: parent.left
                        topMargin: 110
                        leftMargin: 10
                  }
            }
            Button {
                  background: Rectangle {
                        color: color_DARKRED
                        border {
                              width: 2
                              color: "black"
                        }
                  }
                  width: 80
                  height: 40
                  anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: 100
                        rightMargin: 10
                  }
                  onClicked: selectColor(background.color)
            }
            Label {
                  text: "For non-color printing:"
                  font.pointSize: 16
                  anchors {
                        top: parent.top
                        left: parent.left
                        topMargin: 170
                        leftMargin: 10
                  }
            }
            Button {
                  background: Rectangle {
                        color: color_BLACK
                        border {
                              width: 2
                              color: "black"
                        }
                  }
                  width: 80
                  height: 40
                  anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: 160
                        rightMargin: 10
                  }
                  onClicked: selectColor(background.color)
            }
            Label {
                  id: lblExplanation
                  wrapMode: Text.WordWrap
                  font.pointSize: 10
                  horizontalAlignment: Text.AlignHCenter
                  anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        margins: 10
                  }
            }
      }
      function showColorPicker() {
            var scorePropName = (mscoreMajorVersion < 4) ? "Score Properties" : "Project Properties";
            lblExplanation.text = "Your choice will be saved as a custom value in " + scorePropName + "; if you change your mind later, simply delete the value there."
            colorWindow.show();
      }
      function selectColor(color) {
            console.log("Color selected: " + color);
            curScore.setMetaTag("handchimesColor", color);
            colorWindow.close();
      }
      function colorPickerClosed() {
            if(curScore.metaTag("handchimesColor")) {
                  console.log("Color picker was closed after selecting color " + curScore.metaTag("handchimesColor"));
                  setHandchimes();
            } else {
                  console.log("Color picker was closed without saving anything");
                  (typeof(quit) === 'undefined' ? Qt.quit : quit)();
            }
      }
      // END: Set up color picker

      function testSanity(note) {
            if(note.headGroup != NoteHeadGroup.HEAD_DIAMOND && note.headGroup != NoteHeadGroup.HEAD_NORMAL) {
                  return false;
            }
            return true;
      }

      function updateNote(note) {
            note.headGroup = NoteHeadGroup.HEAD_DIAMOND;
            note.color = curScore.metaTag("handchimesColor");
            if (note.accidental) {
                  note.accidental.color = curScore.metaTag("handchimesColor");
            }
            if (note.dots) {
                  for (var i = 0; i < note.dots.length; i++) {
                        note.dots[i].color = curScore.metaTag("handchimesColor");
                  }
            }
      }
      function updateStem(stem) { // also for hooks and beams
            stem.color = curScore.metaTag("handchimesColor");
      }

      function setHandchimes() {
            // Get current selection, or Select All
            var fullScore = !curScore.selection.elements.length;
            if (fullScore) {
                  cmd("select-all");
            }
            curScore.startCmd();
      
            // Sanity check: do all selected notes currently have an expected note head group?
            var numUnknown = 0;
            for(var i in curScore.selection.elements) {
                  if (curScore.selection.elements[i].type == Element.NOTE)
                        if (!testSanity(curScore.selection.elements[i]))
                              numUnknown++;
            }
            if(numUnknown == 1) {
                  showError("Found a note whose note head is neither Standard nor Diamond.  Either change the note head, or exclude it from the selection if it's for a different instrument.");
            } else if(numUnknown > 1) {
                  showError("Found " + numUnknown + " notes whose note heads are neither Standard nor Diamond.  Either change the note heads, or exclude them from the selection if they're for a different instrument.");
            } else {
                  for(var i in curScore.selection.elements) {
                        if (curScore.selection.elements[i].type == Element.NOTE)
                              updateNote(curScore.selection.elements[i]);
                        if (curScore.selection.elements[i].type == Element.STEM)
                              updateStem(curScore.selection.elements[i]);
                        if (curScore.selection.elements[i].type == Element.HOOK)
                              updateStem(curScore.selection.elements[i]);
                        if (curScore.selection.elements[i].type == Element.BEAM)
                              updateStem(curScore.selection.elements[i]);
                  }
            }

            // Finish
            curScore.endCmd();
            if (fullScore) {
                  cmd("escape");
            }
            (typeof(quit) === 'undefined' ? Qt.quit : quit)();
      }
      
      onRun: {
            if(curScore.metaTag("handchimesColor") && curScore.metaTag("handchimesColor").match(/^#[a-f\d]{6}$/)) {
                  console.log("Got existing color preference: " + curScore.metaTag("handchimesColor"));
                  setHandchimes();
            } else {
                  showColorPicker();
            }
      }
}
