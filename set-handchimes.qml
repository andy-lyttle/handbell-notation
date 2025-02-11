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
import "DialogBox.js" as DialogBox

MuseScore {
      id: msParent
      version:  "1.1"
      description: qsTr("Sets the selected notes to use red diamond noteheads (or whatever color you prefer). Does not affect playback. If no notes are selected, updates the color of all notes with diamond heads.")
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

      function changeNote(note) {
            note.headGroup = NoteHeadGroup.HEAD_DIAMOND;
            note.color = curScore.metaTag("handchimesColor");
            if(note.accidental) {
                  note.accidental.color = curScore.metaTag("handchimesColor");
            }
            if(note.dots) {
                  for (var i = 0; i < note.dots.length; i++) {
                        note.dots[i].color = curScore.metaTag("handchimesColor");
                  }
            }
      }
      function changeStem(stem) { // also for hooks and beams
            stem.color = curScore.metaTag("handchimesColor");
      }
      function updateExistingNote(note) { 
            // Existing handchime note already has correct head group, but may need
            // its color updated, along with associated stem/hook/beam if appropriate
            var desiredColor = curScore.metaTag("handchimesColor");
            var anyChanges = false;
            if(note.color != desiredColor) {
                  anyChanges = true;
                  note.color = desiredColor;
            }
            if(note.accidental) {
                  if(note.accidental.color != desiredColor) {
                        anyChanges = true;
                        note.accidental.color = desiredColor;
                  }
            }
            if(note.dots) {
                  for (var i = 0; i < note.dots.length; i++) {
                        if(note.dots[i].color != desiredColor) {
                              anyChanges = true;
                              note.dots[i].color = desiredColor;
                        }
                  }
            }
            
            // If all notes in the chord are handchimes, then set the stem and hook color
            // too, otherwise leave them as-is
            var chord = note.parent;
            var allChimes = true;
            for(var i in chord.notes) {
                  if(chord.notes[i].headGroup != NoteHeadGroup.HEAD_DIAMOND) allChimes = false;
            }
            if(allChimes) {
                  if(chord.stem && chord.stem.color != desiredColor) {
                        anyChanges = true;
                        chord.stem.color = desiredColor;
                  }
                  if(chord.hook && chord.hook.color != desiredColor) {
                        anyChanges = true;
                        chord.hook.color = desiredColor;
                  }
            }
            
            // If this chord is beamed, and all notes in all chords on the beam are
            // handchimes, then set the beam color, otherwise leave it as-is
            if(allChimes && chord.beam) {
                  for(i in chord.beam.elements) {
                        if(!chord.beam.elements[i]) continue;
                        for(var j in chord.beam.elements[i]) {
                              var otherNote = chord.beam.elements[i][j];
                              if(otherNote.type != Element.NOTE) continue;
                              if(otherNote.headGroup != NoteHeadGroup.HEAD_DIAMOND) allChimes = false;
                        }
                  }
                  if(allChimes && chord.beam.color != desiredColor) {
                        anyChanges = true;
                        chord.beam.color = desiredColor
                  }
            }
            
            return anyChanges;
      }

      function setHandchimes() {
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
                              DialogBox.showError("Nothing was selected, but the score contains a note that is not recognized as either handbells or handchimes.  Either select the specific range of notes you want to update, or change this note to use a Standard or Diamond note head.");
                        } else {
                              DialogBox.showError("Nothing was selected, but the score contains " + allNotes["Unknown"].length + " notes that are not recognized as either handbells or handchimes.  Either select the specific range of notes you want to update, or change these notes to use Standard or Diamond note heads.");
                        }
                  } else {
                        // Notes were selected
                        if(allNotes["Unknown"].length == 1) {
                              DialogBox.showError("The selection includes a note that is not recognized as either handbells or handchimes.  Either exclude this note from your selection, or change the note to use a Standard or Diamond note head.");
                        } else {
                              DialogBox.showError("The selection includes " + allNotes["Unknown"].length + " notes that are not recognized as either handbells or handchimes.  Either exclude these notes from your selection, or change the notes to use Standard or Diamond note heads.");
                        }
                  }
            } else if(!(allNotes["Handbells"].length + allNotes["Handchimes"].length)) {
                  // No handbell or handchime notes selected
                  if(fullScore) {
                        DialogBox.showWarning("No notes were found in the score.");
                  } else {
                        DialogBox.showWarning("Something was selected, but the selection didn't include any notes.  Be careful to select the range of notes you want to update.");
                  }
            } else if(fullScore) {
                  if(!allNotes["Handchimes"].length) {
                        // Only handbell notes exist
                        DialogBox.showWarning("All notes in the score are currently set to handbells.  If you really want to change them all to handchimes, please Select All first.  Otherwise, select only the notes you want to change.");
                  } else {
                        // Update color of existing handchime notes, plus associated hooks and beams
                        var updatedCount = 0;
                        var ignoredCount = 0;
                        for(var i in allNotes["Handchimes"]) {
                              if(updateExistingNote(allNotes["Handchimes"][i])) { // also update associated stem, hook and beam if appropriate
                                    updatedCount++;
                              } else {
                                    ignoredCount++;
                              }
                        }
                        if(updatedCount == 1) {
                              DialogBox.showInfo("Updated one existing handchime note to use your selected color.");
                        } else if(updatedCount) {
                              DialogBox.showInfo("Updated " + updatedCount + " existing handchime notes to use your selected color.");
                        } else if(ignoredCount == 1) {
                              DialogBox.showWarning("Nothing was selected.  You already have one note set to handchimes, and " + allNotes["Handbells"].length +  " set to handbells.");
                        } else {
                              DialogBox.showWarning("Nothing was selected.  You already have " + ignoredCount +  " notes set to handchimes, and " + allNotes["Handbells"].length +  " set to handbells.");
                        }
                  }
            } else {
                  // Selection may include some combination of handbell and handchime notes.
                  // Even if all selected notes are already set to handchimes, we should
                  // update the color anyway.  Also update any selected stems, hooks and beams,
                  // but do not touch any other selected elements such as rests.
                  for(var i in curScore.selection.elements) {
                        var e = curScore.selection.elements[i];
                        if(e.type == Element.NOTE) changeNote(e);
                        if(e.type == Element.STEM) changeStem(e);
                        if(e.type == Element.HOOK) changeStem(e);
                        if(e.type == Element.BEAM) changeStem(e);
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
