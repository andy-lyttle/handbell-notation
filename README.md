# Handbell Notation Plugins

A collection of plugins to assist with writing music for handbells and handchimes
in MuseScore Studio.

## Installation

Click the green "&lt;&gt; Code" button and click "Download Zip", unzip it, and
move the "handbell-notation" folder inside your Plugins folder.  This is normally
in your Documents folder under MuseScore3 or MuseScore4.

Then, in MuseScore, choose "Manage Plugins…" or "Plugin Manager…" from the Plugins
manager.  In MuseScore 3, check the boxes next to the plugins you want to enable.
In MuseScore 4, select each plugin and click the "Enable" button in the bottom
right corner.

There should now be a submenu under the Plugins menu called "Composing/arranging
tools" in MuseScore 4, or "Handbell Notation" in MuseScore 3.  You must have a
score open to use these plugins.

## Usage

### Get Handbells Used

<img src="get-handbells-used.png" alt="get-handbells-used" width=256>

Analyzes all notes within the current selection, or the whole score if nothing
is selected, and produces a list of handbells and handchimes used.

Does not insert an actual Handbells Used chart at the beginning of your score.
I may explore the feasibility of doing so in a future version, but for now it
just gives you a list as text.

Unfortunately the normal keyboard shortcut to close a window (⌘W on Mac, Ctrl-W
on Windows/Linux) does *not* close the Handbells Used window, and will instead
close your score.  Use the mouse to click the close button.  (Developers, let me
know if you know of a way to fix this.)

Be careful to select the complete range you want to analyze (or make sure nothing
is selected).  If you have a bells used chart at the beginning of your score, you
should exclude it from your selection.

#### Handbells vs. Handchimes

Notes with normal note heads are assumed to be handbells.  Notes with diamond
note heads are assumed to be handchimes.  Notes with any other note heads will be
listed as "Unknown".  These are each listed separately, as you'd expect.

#### Accidentals and Enharmonics

If notes with the same pitch are written in more than one way in your score
(e.g. D♯ and E♭), both names will be grouped together in parentheses.

#### Octaves

Handbells are a transposing instrument; they sound one octave higher than written,
so a note written as C4 (middle-C) will sound like C5, and should be listed as C5.
In MuseScore 4.x, the "Hand Bells" instrument is set up this way by default, but
in MuseScore 3.x it isn't.  And some of us prefer to use the "Piano" instrument
for writing handbell music, which is also non-transposing.

The plugin tries to do the right thing in all these cases, but due to some bizarre
limitations of MuseScore's plugin API, it has to make some guesses about details
it doesn't have access to, and if it guesses wrong, the report might list your
notes in the wrong octave.

The desired behavior is to report the notes as one octave higher than written,
regardless of which instrument is used or which octave they sound like.  For
example, if a note is written as middle-C (on the first ledger line above the
bass clef), it should be reported as C5.

The actual behavior is to get the pitch the note sounds like, and report that pitch
as-is if you're using the "Hand Bells" instrument in MuseScore 4, or one octave
higher in all other cases (e.g. "Hand Bells" in MuseScore 3, or "Piano" in either
version).  For example, if you're using "Hand Bells" in MuseScore 4 with default
settings, a note written as middle-C will sound as C5, and will be reported as C5.
If you're using "Piano", or "Hand Bells" in MuseScore 3, a note written as middle-C
will sound as C4, and the plugin will add an octave to report it as C5.  However,
if you manually change the octave in Staff/Part Properties, the plugin won't know
what the written pitch is and will report it incorrectly.

This should be good enough for the most common scenarios, but if you're doing
something else, you may get notes reported in the wrong octave.

### Set Selected Notes to Handbells

<img src="set-handbells.png" alt="set-handbells" width=256>   

Changes the note head for all of the selected notes (or all notes in the score
if nothing is selected) to standard, and sets the color to black.  This is intended
for changing handchime notes to handbells.

Dots and accidentals belonging to the selected notes will also be updated, but
stems, hooks and beams will only be updated if they are included in the selection.
They will be included if you select a range, but not if you select only individual
note heads.  Rests and other elements, even if selected, will be ignored.

If any of the selected notes use some note head other that standard or diamond,
you'll get an error; fix these manually, or exclude them from your selection.

### Set Selected Notes to Handchimes

<img src="set-handchimes.png" alt="set-handchimes" width=256>

Changes the note head for all of the selected notes (or all notes in the score
if nothing is selected) to diamond, and sets the color to red (if you like).
This is intended for changing handbell notes to handchimes.

The first time you use the plugin in a particular score, you will be asked to
choose your preferred color.  Bright red is best for printing (it looks different
on paper) but can be hard to look at on a screen, so you can also choose a darker
red if you prefer, or choose black if you won't be printing in color.  Your choice
is saved as a custom field called "handchimeColor" in Project Properties (or
Score Properties in MuseScore 3), so if you change your mind later, you can edit
the hex value there or simply delete the field if you want to be asked again.

Dots and accidentals belonging to the selected notes will also be updated, but
stems, hooks and beams will only be updated if they are included in the selection.
They will be included if you select a range, but not if you select only individual
note heads.  Rests and other elements, even if selected, will be ignored.

If any of the selected notes use some note head other that standard or diamond,
you'll get an error; fix these manually, or exclude them from your selection.

## Version compatibility

These plugins are intended to work with both MuseScore 3.x and MuseScore 4.x on
Windows, Mac and Linux, but have only been tested in 3.6.2 and 4.4 on Mac.
As with most plugins, it is very likely that they will break in a future version
of MuseScore, and will need to be rewritten.

Known differences between versions:
- In MuseScore 3.x, all plugins will appear under a "Handbell Notation" submenu
under the Plugins menu.  In MuseScore 4.x, they appear under "Composing/arranging tools"
(which may be shared by other unrelated plugins).
- Graphics are not used by MuseScore 3.x.
- In MuseScore 3.x, the "Hand Bells" instrument is assumed to be non-transposing,
just like "Piano".  In MuseScore 4.x, the "Hand Bells" instrument is assumed to be
transposing by one octave.  These are the default settings in each version.

## Artwork
Handbell artwork © 2007-2012 Tena Luben, A Familiar Ring  
<https://www.afamiliarring.com/handbell-pictures.htm>
