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
      description: "Gets a list of handbells or handchimes used within the selection, and presents a list as text.  Does NOT insert a chart into your score, sorry.  KNOWN ISSUE: might pick the wrong octave if it guesses wrong about using a transposing instrument, due to limitations of MuseScore's plugin API.  Also, you must use the mouse to close the window that pops up, not the keyboard."
      menuPath: "Plugins.Handbell Notation.Get Handbells Used" // Ignored in MuseScore 4

      // These special comments are parsed by MuseScore 4.4, but ignored by older versions:
      //4.4 title: "Get Handbells Used"
      //4.4 thumbnailName: "get-handbells-used.png"
      //4.4 categoryCode: "composing-arranging-tools"
      
      // The same thing for MuseScore 4.0-4.3, ignored by 4.4:
      Component.onCompleted: {
            if (mscoreMajorVersion == 4 && mscoreMinorVersion <= 3) {
                  title = "Get Handbells Used";
                  thumbnailName = "get-handbells-used.png";
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
      
      // BEGIN: Set up Handbells Used window
      ApplicationWindow {
            id: bellsUsedWindow
            title: "Handbells Used"
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
      // END: Set up Handbells Used window
      
      property string u_DOUBLEFLAT: String.fromCharCode(55348,56619); // U+1D12B
      property string u_FLAT: "\u266D";
      property string u_NATURAL: "";
      property string u_SHARP: "\u266F";
      property string u_DOUBLESHARP: String.fromCharCode(55348, 56618); // U+1D12A
      property string tpc_Names: "FCGDAEB";
      property var tpc_Accidentals: [u_DOUBLEFLAT, u_FLAT, u_NATURAL, u_SHARP, u_DOUBLESHARP];
      property var canonical_Names: ["C", "C\u266F", "D", "D\u266F", "E", "F", "F\u266F", "G", "G\u266F", "A", "A\u266F", "B"];

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
            var staff = note.staff;
            var part = staff.part;
            if(part.instruments.length == 1) {
                  var instrument = part.instruments[0];
            } else {
                  var chord = note.parent;
                  var segment = chord.parent;
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
                        
            return {
                  "notePitch": writtenPitch,
                  "noteName": noteName,
                  "accidentalValue": noteAccidentalValue,
                  "noteCanonicalName": noteCanonicalName,
                  "bellType": bellType
            };
      }

      onRun: {
            // Get current selection, or Select All
            var fullScore = !curScore.selection.elements.length;
            if (fullScore) {
                  cmd("select-all");
            }
            curScore.startCmd();
            
            var allUsed = {
                  "Handbells": {},
                  "Handchimes": {},
                  "Unknown": {}
            };
            for(var i in curScore.selection.elements) {
                  if (curScore.selection.elements[i].type == Element.NOTE) {
                        var bell = getNote(curScore.selection.elements[i]);
                        if(!allUsed[bell.bellType][bell.notePitch]) {
                              allUsed[bell.bellType][bell.notePitch] = {
                                    "canonicalName": bell.noteCanonicalName,
                                    "notes": {},
                                    "count": 0
                              };
                        }
                        allUsed[bell.bellType][bell.notePitch].notes[bell.noteName] = bell.accidentalValue;
                        allUsed[bell.bellType][bell.notePitch].count++;
                        if(bell.noteName == bell.noteCanonicalName) {
                              console.log("Found " + bell.bellType + " note " + bell.noteName);
                        } else {
                              console.log("Found " + bell.bellType + " note " + bell.noteName + " (" + bell.noteCanonicalName + ")");
                        }
                  }
            }

            text1.text = ""
            for(var bellType in allUsed) { // Handbells, Handchimes, and possibly Unknown
                  var numUsed = Object.keys(allUsed[bellType]).length;
                  if(numUsed) { // Do any notes exist of this type?
                        text1.text += bellType + " Used: " + numUsed + "\n";
                        for(var notePitch in allUsed[bellType]) { // All canonical pitches (natural and sharp only) in chromatic order
                              var noteNames = Object.keys(allUsed[bellType][notePitch]["notes"]);
                              if(noteNames.length > 1) {
                                    // Sort enharmonic equivalents by accidental in order from double-sharp to double-flat
                                    noteNames.sort (function(a,b) {
                                          return allUsed[bellType][notePitch]["notes"][b] - allUsed[bellType][notePitch]["notes"][a]
                                    });
                                    text1.text += "  ( " + noteNames.join(", ") + " ) [" + allUsed[bellType][notePitch]["count"] + "]\n";
                              } else {
                                    // This pitch only has one note name (no enharmonic equivalents)
                                    text1.text += "  " + noteNames[0] + " [" + allUsed[bellType][notePitch]["count"] + "]\n";
                              }
                        }
                        text1.text += "\n";
                  }
                  
            }
            if(text1.text == "") {
                  // No notes were found within the selection
                  if(fullScore) {
                        showWarning("No notes were found in the score.");
                  } else {
                        showWarning("Something was selected, but the selection didn't include any notes.  Either select the range of notes to analyze, or be careful not to have anything selected.");
                  }
            } else {
                  bellsUsedWindow.visible = true;
                  
                  // Any Unknown notes?
                  var numUnknown = Object.keys(allUsed["Unknown"]).length;
                  if(numUnknown==1) {
                        showInfo("Found a note whose note head is neither Standard nor Diamond.  You may want to change the note head, or exclude it from the selection if it's for a different instrument.");
                  } else if(numUnknown > 1) {
                        showInfo("Found " + numUnknown + " notes whose note heads are neither Standard nor Diamond.  You may want to change the note heads, or exclude them from the selection if they're for a different instrument.");
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
