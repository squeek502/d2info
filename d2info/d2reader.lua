local memreader = require('memreader')
local constants = require('d2info.constants')
local utils = require('d2info.utils')
local offsetsTable = require('d2info.offsets')
local binary = require('d2info.binary')

local uint32, uint16 = binary.decode_uint32, binary.decode_uint16

local D2Reader = {}
D2Reader.__index = D2Reader

function D2Reader.new()
  local self = setmetatable({}, D2Reader)
  self.process = nil
  self.offsets = nil
  self.status = "Initializing"
  self.isPlugY = nil
  self.d2ClientDLL = nil
  self:init()
  return self
end

function D2Reader:init()
  self.process = self.process or self:openProcess()
  if not self.process then
    self.status = "Waiting for Diablo II process"
    return
  end

  local version, err = self.process:version()
  if not version then
    self.status = "Error: " .. err
    return
  end

  version = utils.friendlyVersion(version.file)
  local d2version = constants.versions[version]
  if not d2version then
    self.status = "Error: Unrecognized Game.exe version: " .. version
    return
  end

  for mod in self.process:modules() do
    if string.lower(mod.name) == "plugy.dll" then
      self.isPlugY = true
    end
    if string.lower(mod.name) == "d2client.dll" then
      self.d2ClientDLL = mod
    end
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

function D2Reader:openProcess()
  local window = memreader.findwindow(constants.windowTitle)
  if window then
    local pid = window.pid
    return assert(memreader.openprocess(pid))
  end
end

function D2Reader:onExit()
  self.process = nil
end

function D2Reader:checkStatus()
  if self.process and self.process:exitcode() then
    self:onExit()
  end
  if not self.process or self.status ~= nil then
    self:init()
  end
  return self.status == nil
end

function D2Reader:getPlayerPointer()
  if not self:checkStatus() then return end
  local playerUnitPtr = uint32(self.process:read(self.base + self.offsets.player, 4))
  return playerUnitPtr ~= 0 and playerUnitPtr or nil
end

function D2Reader:getPlayerName()
  if not self:checkStatus() then return end
  local player = self:getPlayerPointer()
  if player then
    local unitDataPtr = uint32(self.process:read(player + self.offsets.playerData, 4))
    local playerName = self.process:read(unitDataPtr + self.offsets.playerName, 16)
    return binary.null_terminate(playerName)
  end
end

function D2Reader:getExperience()
  if not self:checkStatus() then return end
  local player = self:getPlayerPointer()
  if player then
    local playerStatListPtr = uint32(self.process:read(player + self.offsets.statList, 4))
    local fullStatsData = self.process:read(playerStatListPtr + self.offsets.fullStats, 8)
    local fullStatsPtr = uint32(fullStatsData)
    local fullStatsLength = uint16(fullStatsData, 4)
    local fullStatsArray = self.process:read(fullStatsPtr, fullStatsLength * 8)

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

    return exp, lvl
  end
end

return D2Reader
