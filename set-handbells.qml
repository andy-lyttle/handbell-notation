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
      version:  "1.1"
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
      function changeNote(note) {
            note.headGroup = NoteHeadGroup.HEAD_NORMAL;
            note.color = color_BLACK;
            if (note.accidental) {
                  note.accidental.color = color_BLACK;
            }
            if(note.dots) {
                  for (var i = 0; i < note.dots.length; i++) {
                        note.dots[i].color = color_BLACK;
                  }
            }
      }
      function changeStem(stem) { // also for hooks and beams
            stem.color = color_BLACK;
      }

      function setHandbells() {
            var fullScore = !curScore.selection.elements.length;
            if (fullScore) {
                  cmd("select-all");
            }
            curScore.startCmd();
      
            // Sanity check: do all selected notes currently have an expected note head group?
            var allNotes = {
                  "Handbells": [],
                  "Handchimes": [],
                  "Unknown": []
            };
            for(var i in curScore.selection.elements) {
                  if (curScore.selection.elements[i].type == Element.NOTE) {
                        var note = curScore.selection.elements[i];
                        if(note.headGroup == NoteHeadGroup.HEAD_NORMAL) {
                              allNotes["Handbells"].push(note);
                        } else if(note.headGroup == NoteHeadGroup.HEAD_DIAMOND) {
                              allNotes["Handchimes"].push(note);
                        } else {
                              allNotes["Unknown"].push(note);
                        }
                  }
            }
            
            if(allNotes["Unknown"].length) {
                  // Found some notes we don't know what to do with
                  var x = (allNotes["Unknown"].length == 1) ? "a note that is" : (allNotes["Unknown"].length + " notes that are");
                  if(fullScore) {
                        // Nothing was selected
                        if(allNotes["Unknown"].length == 1) {
                              showError("Nothing was selected, but the score contains a note that is not recognized as either handbells or handchimes.  Either select the specific range of notes you want to update, or change this note to use a Standard or Diamond note head.");
                        } else {
                              showError("Nothing was selected, but the score contains " + allNotes["Unknown"].length + " notes that are not recognized as either handbells or handchimes.  Either select the specific range of notes you want to update, or change these notes to use Standard or Diamond note heads.");
                        }
                  } else {
                        // Notes were selected
                        if(allNotes["Unknown"].length == 1) {
                              showError("The selection includes a note that is not recognized as either handbells or handchimes.  Either exclude this note from your selection, or change the note to use a Standard or Diamond note head.");
                        } else {
                              showError("The selection includes " + allNotes["Unknown"].length + " notes that are not recognized as either handbells or handchimes.  Either exclude these notes from your selection, or change the notes to use Standard or Diamond note heads.");
                        }
                  }
            } else if(!(allNotes["Handbells"].length + allNotes["Handchimes"].length)) {
                  // No handbell or handchime notes selected
                  if(fullScore) {
                        showWarning("No notes were found in the score.");
                  } else {
                        showWarning("Something was selected, but the selection didn't include any notes.  Be careful to select the range of notes you want to update.");
                  }
            } else if(!allNotes["Handchimes"].length) {
                  // All selected notes are already handbells
                  if(fullScore) {
                        if(allNotes["Handbells"].length == 1) {
                              showWarning("We only found one note in the score, which already has a normal note head.  Nothing to do.");
                        } else {
                              showWarning("All " + allNotes["Handbells"].length + " notes in the score already have normal note heads.  Nothing to do.");
                        }
                  } else {
                        if(allNotes["Handbells"].length == 1) {
                              showWarning("The only selected note already has a normal note head.  Nothing to do.");
                        } else {
                              showWarning("All " + allNotes["Handbells"].length + " selected notes already have normal note heads.  Nothing to do.");
                        }
                  }
            } else {
                  // Selection includes some handchime notes, but include other elements to be updated too
                  for(var i in curScore.selection.elements) {
                        var e = curScore.selection.elements[i];
                        if(e.type & Element.NOTE) changeNote(e);
                        if(e.type & (Element.STEM | Element.HOOK | Element.BEAM)) changeStem(e);
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
            setHandbells();
      }
}
