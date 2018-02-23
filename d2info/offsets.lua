return {
  ["1.14d"] = {
    player=0x003A5E74, -- relative to (base|client.dll) address
    area=0x003A3140, -- relative to (base|client.dll) address
    gameId=0x00482D0C, -- relative to (base|net.dll) address
    world=0x00483D38, -- relative to (base|game.dll) address
    playersX=0x00483D70, -- relative to (base|game.dll) address
  },
  ["1.14c"] = {
    player=0x0039CEFC,
    area=0x0039A1C8,
    gameId=0x00479C94,
    world=0x0047ACC0,
    playersX=0x0047ACF8,
  },
  ["1.14b"] = {
    player=0x0039DEFC,
    area=0x0039B1C8,
    gameId=0x0047AD4C,
    world=0x0047BD78,
    playersX=0x0047BDB0,
  },
  ["1.13d"] = {
    player=0x0011D050,
    area=0x0008F66C,
    gameId=0x0000B420,
    world=0x00111C10,
    playersX=0x00111C44,
  },
  ["1.13c"] = {
    player=0x0011BBFC,
    area=0x0011C310,
    gameId=0x0000B428,
    world=0x00111C24,
    playersX=0x00111C1C,
  },
  ["common"] = {
    playerData=0x14, -- relative to player address
    playerName=0x00, -- relative to playerData address
    statList=0x5C, -- relative to player address
    fullStats=0x48, -- relative to statList address
    statListGamePointer=0x60, -- relative to statList address
    gameDifficulty=0x6D, -- relative to game address
    gameCurrentFrame=0xA8, -- relative to game address
    worldGameBuffer=0x1C, -- relative to world address
    worldGameMask=0x24, -- relative to world address
  },
}
