local lfs = require('lfs')

local DEFAULT_CONFIG_NOTE = [=[--[[

  NOTE: This file is not used by d2info and will get overwritten on every run of d2info.

  Instead, it is intended to be used as a reference for updating your config
  file after updating to a new version of d2info (to see new config options, etc).

]]--

]=]
local DEFAULT_CONFIG = [[
return {
  -- time between updates, in milliseconds
  UPDATE_PERIOD = 1000,

  -- maximum duration spent in each town that will count towards exp/min calculations
  -- (e.g. with a value of 30, spending longer than 30 seconds in any given town will only
  -- count as 30 seconds when calculating exp/min using game time)
  -- this allows for doing things like stash management without affecting the stats too much
  MAX_TOWN_DURATION = 20,

  -- enable/disable outputting info to the console screen
  OUTPUT_TO_SCREEN = true,

  -- enable/disable outputting info to files
  OUTPUT_TO_FILE = true,

  -- show information about the area you are currently in, such as: area level,
  -- percentage xp gain from monsters/champions/uniques in that area, etc
  SHOW_AREA_INFORMATION = false,

  -- time in seconds to make tick-party.txt non-empty after gaining an XP tick
  TICK_PARTY_DURATION = 30,
}
]]

local Config = {}
Config.__index = Config

function Config.new(file, defaultFile)
  local self = setmetatable({}, Config)
  self.default = assert(loadstring(DEFAULT_CONFIG))()
  self.config = {}
  self.file = file or "d2info-config.lua"
  self.defaultFile = defaultFile or "d2info-config-default.lua"
  self:load(file)
  self:write(self.defaultFile, DEFAULT_CONFIG_NOTE .. DEFAULT_CONFIG)
  return self
end

local function resolve(t, ...)
  local keys = {...}
  local key = table.remove(keys, 1)
  if #keys == 0 then
    return t[key]
  end
  if not t[key] then
    return nil
  end
  return resolve(t[key], keys)
end

-- Gets a config value by resolving its keys in order
-- e.g. get('a', 'b') will return config['a']['b']
function Config:get(...)
  local v = resolve(self.config, ...)
  if v == nil then
    v = resolve(self.default, ...)
  end
  return v
end

function Config:load(file)
  if not file then file = self.file end
  if not self:exists(file) then
    self:write(file, DEFAULT_CONFIG)
    return
  end
  local f = assert(io.open(file))
  local str = f:read("*all")
  local fn = assert(loadstring(str, file))
  local loaded = fn()
  self.config = loaded
end

function Config:write(file, data)
  if not file then file = self.file end
  local f = assert(io.open(file, "w"))
  f:write(data)
  f:close()
end

function Config:exists(file)
  if not file then file = self.file end
  return lfs.attributes(file) ~= nil
end

return Config
