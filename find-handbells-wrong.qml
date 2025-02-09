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
      description: "Checks the selected notes to see if any are on the wrong staff for handbells."
      menuPath: "Plugins.Find Handbells On the Wrong Staff" // Ignored in MuseScore 4

      // These special comments are parsed by MuseScore 4.4, but ignored by older versions:
      //4.4 title: "Find Handbells On the Wrong Staff"
      //4.4 thumbnailName: "find-handbells-wrong.png"
      //4.4 categoryCode: "composing-arranging-tools"
      
      // The same thing for MuseScore 4.0-4.3, ignored by 4.4:
      Component.onCompleted: {
            if (mscoreMajorVersion == 4 && mscoreMinorVersion <= 3) {
                  title = "Find Handbells On the Wrong Staff";
                  thumbnailName = "find-handbells-wrong.png";
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
      
      // BEGIN: Set up results window
      ApplicationWindow {
            id: resultsWindow
            title: "Handbells On the Wrong Staff"
            width: 600
            height: 500

            ScrollView {
                  id: view1
                  anchors.fill: parent
                  TextArea {
                        id: text1
                        text: ""
                        readOnly: true
                        wrapMode: Text.WordWrap
                        selectByMouse: true
                        font.family: "Edwin"
                        font.pointSize: 16
                  }
            }
      }
      // END: Set up results window
      
      property string u_DOUBLEFLAT: String.fromCharCode(55348,56619) // U+1D12B
      property string u_FLAT: "\u266D"
      property string u_NATURAL: ""
      property string u_SHARP: "\u266F"
      property string u_DOUBLESHARP: String.fromCharCode(55348, 56618) // U+1D12A
      property string tpc_Names: "FCGDAEB"
      property var tpc_Accidentals: [u_DOUBLEFLAT, u_FLAT, u_NATURAL, u_SHARP, u_DOUBLESHARP]
      property var canonical_Names: ["C", "C\u266F", "D", "D\u266F", "E", "F", "F\u266F", "G", "G\u266F", "A", "A\u266F", "B"]
      property string color_BAD: "#00ff00"
      
      function getNote(note) {
            // Handbells are a transposing instrument, so what is written as middle-C
            // (which would be C4 on a piano unless you're Yamaha for some reason) sounds
            // like C5 on handbells, and needs to be labeled as C5.  In MuseScore 4, the
            // "Hand Bells" instrument is set to transpose up an octave by default,
            // so what's written as middle-C on the staff sounds like C5, which is exactly
            // correct... but that wasn't the default behavior in MuseScore 3.  Also, some
            // of us prefer to use the "Piano" instrument to write our handbell music.
            // 
            // The desired behavior here would be to generate our bells used chart based
            // on the notes one octave higher than they are written on the staff,
            // regardless of whether MuseScore is using a transposing instrument
            // or not.  Unfortunately, it appears that the MuseScore plugin API does not
            // expose transposition information.  We get the octave from the MIDI pitch,
            // so if a note sounds like C5, we don't know if it's written as middle-C
            // for a transposing instrument ("Hand Bells" in MuseScore 4), or written as
            // high-C for a non-transposing instrument ("Hand Bells" in MuseScore 3, or
            // piano).  If it's written as middle-C we want to call it C5, but if it's
            // written as high-C we want to call it C6, and as best I can tell the API
            // doesn't tell us.
            //
            // For example, the following DO NOT work:
            //       note.transposition (undefined)
            //       note.ppitch (undefined)
            //       note.epitch (undefined)
            //       note.playEvents[0].pitch (always 0)
            //
            // So, we'll have to guess.  And we could guess wrong.
            // 
            // First, we figure out what instrument we're using.  If this part only has
            // one instrument, then we know that must be the correct one, otherwise we
            // have to figure it out for each note (slower) to correctly handle any
            // instrument changes.
            var chord = note.parent;
            var segment = chord.parent;
            var staff = note.staff;
            var part = staff.part;
            if(part.instruments.length == 1) {
                  var instrument = part.instruments[0];
            } else {
                  var instrument = part.instrumentAtTick(segment.tick);
            }

            // Now we guess that if you're using the "Hand Bells" instrument in MuseScore
            // 4.x (instrumentId "hand-bells"), it is a transposing instrument, so
            // everything sounds an octave higher than written.  Otherwise, we guess that
            // your instrument is concert pitch.  If you use the "Hand Bells" instrument
            // in MuseScore 3.x (instrumentId "pitched-percussion.handbells") but change
            // the Staff/Part Properties to make it transpose, or if you use some other
            // transposing instrument, then we will get this wrong.
            if (instrument.instrumentId == "hand-bells") {
                  var transpositionOffset = 12;
            } else {
                  var transpositionOffset = 0;
            }
            var writtenPitch = note.pitch - transpositionOffset;
            
            // Use the note's Tonal Pitch Class to see how the pitch is written, including
            // flats or sharps (which could be accidentals or in the key signature, but
            // we'll call them accidentals here).  We'll represent the accidental as an
            // integer (-1 for flat, 0 for natural, 1 for sharp), then convert that to a
            // human-readable Unicode character.
            var noteLetter = tpc_Names[(note.tpc + 1) % 7];
            var noteAccidentalValue = Math.floor((note.tpc + 1) / 7) - 2;
            var noteAccidentalString = tpc_Accidentals[noteAccidentalValue + 2];
            
            // TPC doesn't give us the octave, so we have to discover that a different
            // way.  Here we use the note's MIDI pitch to derive the octave.  However, we
            // have to take flats and sharps into account.  For example, we want to
            // consider Cb5 to be in octave 5, even though the MIDI pitch is B4.  So, we
            // simply take the MIDI pitch (B4 in this example), subtract the accidental
            // value (flat is -1, so subtracting -1 is the same as adding 1, which gives
            // us the MIDI pitch C5), and use that octave.
            //
            // The math here actually gives us one octave higher than the MIDI pitch,
            // which is what we want.
            var noteOctave = Math.floor((writtenPitch - noteAccidentalValue) / 12);
            
            // We're still not completely sure about octave transposing instruments, so
            // let's check the note's vertical position on the staff to see if we can
            // confirm our guess that way.  We only correctly support treble and bass
            // clefs here.
            var posY = Math.round(note.posY * 10) / 10; // Fix floating-point glitches like 3.5000000000000004
            var letterValue = (noteLetter.charCodeAt(0) - 4) % 7; // Convert note letter to 0-6
            var staffOffset = (noteOctave * 7 + letterValue) / 2; // C0 = 0, D0 = 0.5, E0 = 1, F0 = 1.5, etc...
            var clef = undefined;
            if(posY == 22.5 - staffOffset) { // Treble clef
                  clef = "Treble";
            } else if(posY == 26 - staffOffset) { // Treble 8va
                  transpositionOffset += 12;
                  clef = "Treble";
            } else if(posY == 19 - staffOffset) { // Treble 8vb
                  transpositionOffset -= 12;
                  clef = "Treble";
            } else if(posY == 16.5 - staffOffset) { // Bass clef
                  clef = "Bass";
            } else if(posY == 20 - staffOffset) { // Bass 8va
                  transpositionOffset += 12;
                  clef = "Bass";
            } else if(posY == 13 - staffOffset) { // Bass 8vb
                  transpositionOffset -= 12;
                  clef = "Bass";
            }
            writtenPitch = note.pitch - transpositionOffset;
            noteOctave = Math.floor((writtenPitch - noteAccidentalValue) / 12);
            
            // Now, concatenate everything together to get a human-readable name like Cb5
            // (but using a fancy Unicode flat symbol instead of a lower-case letter "b").
            // Double flats and double sharps are supported too, but no other weird
            // accidentals.
            var noteName = noteLetter + noteAccidentalString + noteOctave;
            
            // Next, we need to know the canonical name for this note, i.e. which actual
            // handbell does this mean?  For example, B4 and Cb5 are two different names
            // for the same pitch, which is really B4.  These will always use sharps,
            // never flats.  We derive this entirely from the MIDI pitch, ignoring TPC.
            var noteCanonicalOctave = Math.floor(writtenPitch / 12);
            var noteCanonicalName = canonical_Names[(writtenPitch % 12)] + noteCanonicalOctave;
            
            // Assume that handchimes are written with diamond note heads, while anything
            // with standard note heads are handbells.  Anything else we'll call Unknown.
            var bellType = "Unknown";
            if(note.headGroup == NoteHeadGroup.HEAD_NORMAL) bellType = "Handbells";
            if(note.headGroup == NoteHeadGroup.HEAD_DIAMOND) bellType = "Handchimes";
            
            console.log("Found " + bellType + " note " + noteName);
            console.log("  Transposed MIDI pitch = " + note.pitch);
            console.log("  Written MIDI pitch = " + writtenPitch + " + transposition offset = " + transpositionOffset);
            console.log("  Canonical name = " + noteCanonicalName);
            console.log("  Instrument " + instrument.longName + " (" + instrument.instrumentId + ")");
            console.log("  Instrument ID = " + instrument.instrumentId);
            
            return {
                  "noteName": noteName,
                  "accidentalValue": noteAccidentalValue,
                  "noteCanonicalName": noteCanonicalName,
                  "letterValue": letterValue,
                  "noteOctave": noteOctave,
                  "clef": clef, // may be undefined or inaccurate
                  "bellType": bellType,
                  "tick": segment.tick
            };
      }
      
      function getSelectedNotes() {
            var selectedNotes = [];
            for(var i in curScore.selection.elements) {
                  if (curScore.selection.elements[i].type == Element.NOTE) {
                        var note = curScore.selection.elements[i];
                        var chord = note.parent;
                        var segment = chord.parent;
                        selectedNotes.push({
                              "note": note,
                              "staffNum": getStaffNum(note.staff),
                              "tick": segment.tick
                        });
                  }
            }
            return selectedNotes;
      }
      

      property var allStaves: []
      function getStaves() {
            // This should be simple and easy!  Unfortunately there's a bug in MuseScore 3.
            if (mscoreMajorVersion < 4) {
                  // We work around the bug by finding the first BeginBarLine at the start
                  // of the score, then querying every possible staff looking for a
                  // BarLine element in the first voice.  If we find one, we can find the
                  // Staff object from there, and if we don't, we can safely assume that
                  // no such staff exists.
                  var cursor = curScore.newCursor();
                  cursor.filter = Segment.BeginBarLine;
                  cursor.rewind(Cursor.SCORE_START);
                  var segment = cursor.segment;
                  for(var staffNum=0; staffNum < 255; staffNum++) {
                        var track = staffNum * 4;
                        var barline = segment.elementAt(track);
                        if(barline) {
                              allStaves.push(barline.staff);
                        } else {
                              break;
                        }
                  }
                  console.log("Found " + allStaves.length + " staves the hard way");
            } else {
                  // If the bug is fixed, do it the easy way.
                  allStaves = curScore.staves;
                  console.log("Found " + allStaves.length + " staves the easy way");
            }
      }
      function getStaffNum(myStaff) {
            for(var i=0; i<allStaves.length; i++) {
                  if(allStaves[i].is(myStaff)) return i;
            }
            console.log("Tried to match a note's staff to the list of known staves in the score, but failed!");
            return undefined;
      }
      
      onRun: {
            // Get current selection, or Select All
            var fullScore = !curScore.selection.elements.length;
            if (fullScore) {
                  cmd("select-all");
            }
            curScore.startCmd();
            
            // Get a list of all notes within the current selection
            getStaves();
            var selectedNotes = getSelectedNotes();
            if(selectedNotes.length) {
                  var problems = [];
                  for(var i in selectedNotes) {
                        var staffNum = selectedNotes[i]["staffNum"];
                        var note = selectedNotes[i]["note"];
                        var chord = note.parent;
                        var segment = chord.parent;
                        var measure = segment.parent;
                        
                        var bell = getNote(note);
                        if(!bell.clef) {
                              problems.push("Found note " + bell.noteName + " in an unknown clef on staff " + (staffNum + 1));
                        } else if(bell.clef == "Treble") {
                              if(bell.noteOctave < 5 || (bell.noteOctave == 5 && bell.letterValue < 1)) { // below D5
                                    note.color = color_BAD;
                                    problems.push("Found " + bell.noteName + " in " + bell.clef + " clef on staff " + (staffNum + 1));
                              }
                        } else if(bell.clef == "Bass") {
                              if(bell.noteOctave > 5 || (bell.noteOctave == 5 && bell.letterValue > 0)) { // above C5
                                    note.color = color_BAD;
                                    problems.push("Found " + bell.noteName + " in " + bell.clef + " clef on staff " + (staffNum + 1));
                              }
                        }
                  }
                  if(problems.length) {
                        if(problems.length == 1) {
                              text1.text = problems[0] + "\n\n1 problem to fix.";
                        } else {
                              text1.text = problems.join("\n") + "\n\n" + problems.length + " problems to fix.";
                        }
                        resultsWindow.visible = true;
                  } else {
                        showInfo("No problems found.");
                  }
            } else {
                  // No notes were found within the selection
                  if(fullScore) {
                        showWarning("No notes were found in the score.");
                  } else {
                        showWarning("Something was selected, but the selection didn't include any notes.  Either select the range of notes to analyze, or be careful not to have anything selected.");
                  }
            }
            
            // Finish
            curScore.endCmd()
            if (fullScore) {
                  cmd("escape");
            }
            (typeof(quit) === 'undefined' ? Qt.quit : quit)();
      }
}
