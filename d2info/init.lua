local memreader = require('memreader')
local D2Reader = require('d2info.d2reader')
local sleep = require('sleep')

memreader.debug_privilege(true)
local reader = D2Reader.new()

while true do
  local name = reader:getPlayerName()
  if name then
    local exp, lvl = reader:getExperience()
    io.write(string.format("\rCharacter '%s' has %u experience (level %d)", name, exp, lvl))
  elseif reader.status ~= nil then
    io.write("\r" .. reader.status)
  else
    io.write("\rNo player")
  end
  sleep(1000)
end
