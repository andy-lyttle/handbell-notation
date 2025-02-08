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
      description: qsTr("Sets the selected notes to use normal black noteheads. Does not affect playback.")
      menuPath: "Plugins.Handbell Notation.Set Selected Notes to Handbells" // Ignored in MuseScore 4

      // These special comments are parsed by MuseScore 4.4, but ignored by older versions:
      //4.4 title: "Set Selected Notes to Handbells"
      //4.4 thumbnailName: "set-handbells.png"
      //4.4 categoryCode: "composing-arranging-tools"
      
      // The same thing for MuseScore 4.0-4.3, ignored by 4.4:
      Component.onCompleted: {
            if (mscoreMajorVersion == 4 && mscoreMinorVersion <= 3) {
                  title = "Set Selected Notes to Handbells";
                  thumbnailName = "set-handbells.png";
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

      property string color_BLACK : "#000000"

      function testSanity(note) {
            if(note.headGroup != NoteHeadGroup.HEAD_DIAMOND && note.headGroup != NoteHeadGroup.HEAD_NORMAL) {
                  return false;
            }
            return true;
      }

      function updateNote(note) {
            note.headGroup = NoteHeadGroup.HEAD_NORMAL;
            note.color = color_BLACK;
            if (note.accidental) {
                  note.accidental.color = color_BLACK;
            }
            if (note.dots) {
                  for (var i = 0; i < note.dots.length; i++) {
                        note.dots[i].color = color_BLACK;
                  }
            }
      }
      function updateStem(stem) { // also for hooks and beams
            stem.color = color_BLACK;
      }

      function setHandbells() {
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
            curScore.endCmd()
            if (fullScore) {
                  cmd("escape");
            }
            (typeof(quit) === 'undefined' ? Qt.quit : quit)();
      }
      
      onRun: {
            setHandbells();
      }
}
