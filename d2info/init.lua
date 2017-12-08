local memreader = require('memreader')
local binary = require('d2info.binary')
local constants = require('d2info.constants')
local utils = require('d2info.utils')
local offsetsTable = require('d2info.offsets')

local uint32, uint16 = binary.decode_uint32, binary.decode_uint16
--local hex_dump = binary.hex_dump

memreader.debug_privilege(true)

local function getD2()
  for _, pid in ipairs(memreader.process_ids()) do
    if memreader.process_name(pid) == "Game.exe" then
      return memreader.open_process(pid)
    end
  end
end

local process = getD2()
if not process then
  print("No Diablo II client found")
  os.exit(1)
end

local version = assert(process:version())
version = utils.friendlyVersion(version.file)
local d2version = constants.versions[version]
if not d2version then
  print("Unrecognized Game.exe version: " .. version)
  os.exit(1)
end

local isPlugY = false
local d2ClientDLL = nil
for _,mod in ipairs(process:modules()) do
  if string.lower(mod.name) == "plugy.dll" then
    isPlugY = true
  end
  if string.lower(mod.name) == "d2client.dll" then
    d2ClientDLL = mod
  end
end
print("Running PlugY: " .. tostring(isPlugY))
print("D2 Client DLL (Versions < 1.14): " .. tostring(d2ClientDLL))

local base = d2ClientDLL and d2ClientDLL.base or process.base
local offsets = offsetsTable[d2version]

if not offsets then
  print("No memory table is available for D2 version " .. d2version)
  os.exit(1)
end

offsets = utils.tableMerge(offsets, offsetsTable.common)

local playerUnitPtr = uint32(process:read(base + offsets.player, 4))
if playerUnitPtr ~= 0 then
  print(string.format("playerUnitPtr: %x", playerUnitPtr))
  local unitDataPtr = uint32(process:read(playerUnitPtr + offsets.playerData, 4))
  print(string.format("unitDataPtr: %x", unitDataPtr))
  local playerName = process:read(unitDataPtr + offsets.playerName, 16)
  playerName = binary.null_terminate(playerName)

  local playerStatListPtr = uint32(process:read(playerUnitPtr + offsets.statList, 4))
  print(string.format("playerStatListPtr: %x", playerStatListPtr))
  local fullStatsData = process:read(playerStatListPtr + offsets.fullStats, 8)
  local fullStatsPtr = uint32(fullStatsData)
  print(string.format("fullStatsPtr: %x", fullStatsPtr))
  local fullStatsLength = uint16(fullStatsData, 4)
  print(string.format("fullStatsLength: %d", fullStatsLength))
  local fullStatsByteSize = uint16(fullStatsData, 6)
  print(string.format("fullStatsByteSize: %d", fullStatsByteSize))
  local fullStatsArray = process:read(fullStatsPtr, fullStatsLength * 8)

  local exp = 0
  for i=0,fullStatsLength-1 do
    local start = i*8
    local lo, v = uint16(fullStatsArray, start+2), uint32(fullStatsArray, start+4)
    if lo == 13 then
      exp = v
    end
  end

  print("Character '" .. playerName .. "' has " .. exp .. " experience")
else
  print("No player")
end
