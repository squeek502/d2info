# d2info

[![Build Status](https://travis-ci.org/squeek502/d2info.svg?branch=master)](https://travis-ci.org/squeek502/d2info)

d2info is a tool for viewing/outputting various information about a running Diablo II game (by reading the memory used by the game).

Currently, it provides the following information:

- Experience per minute over different time periods:
  - Real time (since the character was first seen by the d2info process)
  - In-game time (only includes time that the character is in a game, not paused, etc)
  - Current game
  - Last game (xp/min of the last game at the point of save+quit)
- Estimated time until the next level, using the various exp/min readings
- Number of runs finished, average xp/min per run, estimated runs until the next level
- Number of experience 'ticks' gained (pixels filled in the experience bar)
- Information about the current area, like monster level and % xp gain (unfinished, disabled by default; see `SHOW_AREA_INFORMATION` in the config)

Supports Diablo II versions 1.13c, 1.13d, 1.14b, 1.14c, and 1.14d (D2SE and/or PlugY are also supported)

## Installation

Simply grab the [latest .exe build from the releases page](https://github.com/squeek502/d2info/releases/latest) and run it.

*Note: You'll probably want to put the .exe in its own folder, as it will output various files relative to its location*

## Running using Lua

- Clone this repository
- Build [memreader](https://github.com/squeek502/memreader), [sleep](https://github.com/squeek502/sleep), [luafilesystem](https://github.com/keplerproject/luafilesystem), and [LuaBitOp](http://bitop.luajit.org/) and make the resulting .dll's available to Lua's `package.cpath`.
- Run `lua d2info.lua`

## Output

The information is output to both the console window and to individual text files (in the directory `output`, relative to d2info) to allow the info to be easily added to stream overlays.

Console output example:
```
CharName (level 96 & 32.85%)
/players 8

Run #6:
 207.8k xp/min (734.2k xp in 3m32s)
 13h until level 97 at this rate

Last run:
 160.7k xp/min (576.0k xp in 3m35s)
 17h until level 97 at this rate

Average run:
 165.0k xp/min (521.0k xp in 3m09s)
 315 runs until level 97

This session:
 +1.6 ticks (+1.36%)
 Next tick in 675.2k xp
 177.8k xp/min (3.3m xp in 19m19s)
 15h until level 97 at this rate
```

### Tick Party

The file `output/tick-party.txt` can be used in conjunction with [the OBS script Txt Trigger](https://obsproject.com/forum/resources/txt-trigger.710/) to show OBS source(s) (video, audio, etc) whenever an experience tick is gained (i.e. when a new pixel is filled in).

![Txt Trigger settings](https://www.ryanliptak.com/misc/txt-trigger.png)

The above settings will use the d2info config option `TICK_PARTY_DURATION` for the amount of time the source(s) are shown. Alternatively, you can uncheck 'Make source(s) visible for as long as file contents match' and set the duration in OBS.

## Acknowledgements

- [DiabloInterface](https://github.com/Zutatensuppe/DiabloInterface) for information about the memory layout of D2 and techniques for reading its memory
- [PlugY](http://plugy.free.fr/en/index.html) for information about the memory layout of D2 and how to determine the version of the game process