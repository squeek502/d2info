local memreader = require('memreader')
local constants = require('d2info.constants')
local utils = require('d2info.utils')
local offsetsTable = require('d2info.offsets')
local binary = require('d2info.binary')
local bit = require('bit')

local uint32, uint16, uint8 = binary.decode_uint32, binary.decode_uint16, binary.decode_uint8

local D2Reader = {}
D2Reader.__index = D2Reader

function D2Reader.new()
  local self = setmetatable({}, D2Reader)
  self.process = nil
  self.offsets = nil
  self.status = "Initializing"
  self.isPlugY = nil
  self.d2ClientDLL = nil
  self.d2GameDLL = nil
  self.d2NetDLL = nil
  self.isD2SE = nil
  self:init()
  return self
end

function D2Reader:init()
  self.process = self.process or self:openProcess()
  if not self.process then
    self.status = "Waiting for Diablo II process"
    return
  end

  self.isD2SE = self.process.name:lower() == constants.d2seExe:lower()

  local d2version
  local shouldHaveDLLs
  if self.isD2SE then
    d2version = assert(self.process:readrelative(offsetsTable["d2se"].d2version, 5))
    d2version = binary.null_terminate(d2version)
    shouldHaveDLLs = true
  else
    local versionInfo, err = self.process:version()
    if not versionInfo then
      self.status = "Error obtaining Game.exe version: " .. err
      self.process = nil
      return
    end

    local version = utils.friendlyVersion(versionInfo.file)
    d2version = constants.versions[version]
    shouldHaveDLLs = versionInfo.file.minor == 0

    if not d2version then
      self.status = "Error: Unrecognized Game.exe version: " .. version
      return
    end
  end

  self.isPlugY = false
  self.d2ClientDLL, self.d2GameDLL, self.d2NetDLL = nil, nil, nil
  for mod in self.process:modules() do
    if string.lower(mod.name) == "plugy.dll" then
      self.isPlugY = true
    end
    if string.lower(mod.name) == "d2client.dll" then
      self.d2ClientDLL = mod
    end
    if string.lower(mod.name) == "d2game.dll" then
      self.d2GameDLL = mod
    end
    if string.lower(mod.name) == "d2net.dll" then
      self.d2NetDLL = mod
    end
  end

  local hasDLLs = self.d2ClientDLL and self.d2GameDLL and self.d2NetDLL
  if shouldHaveDLLs and not hasDLLs then
    self.status = "Waiting for D2 dlls to be loaded"
    return
  end

  self.base = self.d2ClientDLL and self.d2ClientDLL.base or self.process.base
  self.offsets = offsetsTable[d2version]

  if not self.offsets then
    self.status = "Error: Not currently compatible with D2 version " .. d2version
    return
  end

  self.offsets = utils.tableMerge(self.offsets, offsetsTable.common)
  self.status = nil
end

local function isValidExe(exe)
  return constants.exe:lower() == exe:lower() or constants.d2seExe:lower() == exe:lower()
end

-- finding the process by window title is fast but can lead to false positives
-- or fail to find it if there are multiple windows with the same title
local function openProcessFast()
  local window = memreader.findwindow(constants.windowTitle)
  if window then
    local process = memreader.openprocess(window.pid)
    if process and isValidExe(process.name) then
      return process
    end
  end
end

local function openProcess()
  for pid, name in memreader.processes() do
    if isValidExe(name) then
      return assert(memreader.openprocess(pid))
    end
  end
end

function D2Reader:openProcess()
  return openProcessFast() or openProcess()
end

function D2Reader:onExit()
  self.process = nil
  self.isPlugY = false
  self.d2ClientDLL, self.d2GameDLL, self.d2NetDLL = nil, nil, nil
  self.base = nil
  self.offsets = nil
end

function D2Reader:checkStatus()
  if self.process and self.process:exitcode() then
    self:onExit()
    return
  end
  if not self.process or self.status ~= nil then
    self:init()
  end
  return self.status == nil
end

function D2Reader:getPlayerPointer()
  if not self:checkStatus() then return end
  local data, err = self.process:read(self.base + self.offsets.player, 4)
  if err then return nil, err end
  local playerUnitPtr = uint32(data)
  return playerUnitPtr ~= 0 and playerUnitPtr or nil
end

function D2Reader:getPlayerName()
  if not self:checkStatus() then return end
  local player = self:getPlayerPointer()
  if player then
    local data, err = self.process:read(player + self.offsets.playerData, 4)
    if err then return nil, err end
    local unitDataPtr = uint32(data)
    local playerName = assert(self.process:read(unitDataPtr + self.offsets.playerName, 16))
    return binary.null_terminate(playerName)
  end
end

function D2Reader:getExperience()
  if not self:checkStatus() then return end
  local player = self:getPlayerPointer()
  if player then
    local playerStatListPtr = uint32(assert(self.process:read(player + self.offsets.statList, 4)))
    local fullStatsData = assert(self.process:read(playerStatListPtr + self.offsets.fullStats, 8))
    local fullStatsPtr = uint32(fullStatsData)
    local fullStatsLength = uint16(fullStatsData, 4)
    local fullStatsArray = assert(self.process:read(fullStatsPtr, fullStatsLength * 8))

    local exp = 0
    local lvl = 1
    for i=0,fullStatsLength-1 do
      local start = i*8
      local lo, v = uint16(fullStatsArray, start+2), uint32(fullStatsArray, start+4)
      if lo == constants.stats.experience then
        exp = v
      elseif lo == constants.stats.level then
        lvl = v
      end
    end

    -- sanity check: level gets loaded into the array before experience, so check to make sure
    -- we're not getting a false 0 experience by comparing exp to level
    if exp < constants.experience[lvl] then
      return
    end

    return exp, lvl
  end
end

function D2Reader:getArea()
  if not self:checkStatus() then return end
  local area = string.byte(assert(self.process:read(self.base + self.offsets.area, 1)))
  -- this will return nil when not in a game (area = 0)
  return constants.areas[area]
end

function D2Reader:getDifficulty()
  if not self:checkStatus() then return end
  local gamePtr = self:getGamePointer()
  if gamePtr then
    local difficulty = uint8(assert(self.process:read(gamePtr + self.offsets.gameDifficulty, 2)))
    return constants.difficulties[difficulty]
  end
end

function D2Reader:getPlayersX()
  if not self:checkStatus() then return end
  local gameBase = self.d2GameDLL and self.d2GameDLL.base or self.base
  local value = uint8(assert(self.process:read(gameBase + self.offsets.playersX, 2)))
  -- a value of 0 means that the setting hasn't been set by
  -- /playersX since D2 started, so the real value is the default of 1
  return value ~= 0 and value or 1
end

function D2Reader:getWorldPointer()
  if not self:checkStatus() then return end
  local gameBase = self.d2GameDLL and self.d2GameDLL.base or self.base
  local data, err = self.process:read(gameBase + self.offsets.world, 4)
  -- treat memory read error here as non-fatal, as this can occur
  -- when the dlls are unloading at game shutdown
  if err then return nil, err end
  local worldPtr = uint32(data)
  return worldPtr ~= 0 and worldPtr or nil
end

function D2Reader:getGamePointer()
  if not self:checkStatus() then return end
  local netBase = self.d2NetDLL and self.d2NetDLL.base or self.base

  local worldPtr = self:getWorldPointer()
  if worldPtr then
    local gameId = uint32(assert(self.process:read(netBase + self.offsets.gameId, 4)))
    local gameMask = uint32(assert(self.process:read(worldPtr + self.offsets.worldGameMask, 4)))
    local gameIndex = bit.band(gameId, gameMask)
    local gameOffset = gameIndex * 0x0C + 0x08
    local gameBuffer = uint32(assert(self.process:read(worldPtr + self.offsets.worldGameBuffer, 4)))
    local gamePtr = uint32(assert(self.process:read(gameBuffer + gameOffset, 4)))
    -- if the sign bit is set, then the pointer is invalid
    local valid = bit.band(gamePtr, 0x80000000) == 0
    return (valid and gamePtr ~= 0) and gamePtr or nil
  end
end

function D2Reader:getCurrentFrameNumber()
  if not self:checkStatus() then return end
  local gamePtr = self:getGamePointer()
  if gamePtr then
    local currentFrame = uint32(assert(self.process:read(gamePtr + self.offsets.gameCurrentFrame, 4)))
    return currentFrame
  end
end

return D2Reader
