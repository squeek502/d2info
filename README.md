# d2info

d2info is a tool for viewing/outputting various information about a running Diablo II game (by reading the memory used by the game).

Currently, it provides the following information:

- Experience per minute over different time periods:
  - Real time (since the character was first seen by the d2info process)
  - In-game time (only includes time that the character is in a game)
  - Current game
  - Last game (xp/min of the last game at the point of save+quit)
- Estimated time until the next level, using the various exp/min readings

Supports Diablo II verisons 1.11, 1.11b, 1.12, 1.13c, 1.13d, 1.14c, and 1.14d

## Installation

Simply grab the [latest .exe build from the releases page](https://github.com/squeek502/d2info/releases/latest) and run it.

### Running using Lua

- Build [memreader](https://github.com/squeek502/memreader) and [sleep](https://github.com/squeek502/sleep) and make the resulting .dll's available to Lua's `package.cpath`.
- Run `lua d2info.lua`

## Sample Output

Currently, the information is just output to the console window. Soon, data will be (optionally?) put into files so that it can easily be added to stream overlays.

```
CoolGuy

Overall (real-time): 167.3k xp/min
Overall (game-time): 183.2k xp/min
Current game: 87.5k xp/min
Last game: 258.7k xp/min

Est time until level 96:
 12h (using real-time xp/min)
 11h (using game-time xp/min)
 23h (using current game's xp/min)
 8h22m (using last game's xp/min)
```

## Acknowledgements

- [DiabloInterface](https://github.com/Zutatensuppe/DiabloInterface) for information about the memory layout of D2 and techniques for reading its memory
- [PlugY](http://plugy.free.fr/en/index.html) for information about the memory layout of D2 and how to determine the version of the game process