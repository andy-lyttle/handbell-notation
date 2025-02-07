/*
 * SPDX-License-Identifier: GPL-3.0-only
 * MuseScore-Studio-CLA-applies
 *
 * MuseScore Studio
 * Music Composition & Notation
 *
 * Copyright (C) 2021 MuseScore Limited
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

      property string color_BLACK : "#000000"
      property string color_RED : "#ff0000"

      function testSanity(note) {
            if(note.headGroup != NoteHeadGroup.HEAD_DIAMOND && note.headGroup != NoteHeadGroup.HEAD_NORMAL) {
                  console.log("Selection includes note head that is not what we expect for either handbells or handchimes.");
                  return false;
            }
            if(note.color != color_BLACK && note.color != color_RED) {
                  console.log("Selection includes a note color that is not what we expect for either handbells or handchimes.");
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
      function updateStem(stem) {
            stem.color = color_BLACK;
      }

      onRun: {
            // Get current selection, or Select All
            var fullScore = !curScore.selection.elements.length
            if (fullScore) {
                  cmd("select-all")
            }
            curScore.startCmd()
            
            // Sanity check: do all selected notes currently have an expected note head group and color?
            var sane = true;
            for(var i in curScore.selection.elements) {
                  if (curScore.selection.elements[i].type == Element.NOTE)
                        if (!testSanity(curScore.selection.elements[i]))
                              sane = false;
            }
            if(sane) {
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
                  cmd("escape")
            }
            (typeof(quit) === 'undefined' ? Qt.quit : quit)();
      }
}
