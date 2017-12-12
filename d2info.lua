local memreader = require('memreader')
local D2Reader = require('d2info.d2reader')
local sleep = require('sleep')
local Session = require('d2info.session')
local Output = require('d2info.output')

memreader.debugprivilege(true)
local reader = D2Reader.new()
local sessions = {}
local output = Output.new()
local lastInfo = {}
local UPDATE_PERIOD = 1000

while true do
  local player = reader:getPlayerName()
  if player then
    local exp, lvl = reader:getExperience()

    if not sessions[player] then
      sessions[player] = {}
      sessions[player].total = Session.new(exp, lvl)
    end
    if sessions[player].current == nil then
      sessions[player].current = Session.new(exp, lvl)
    end

    local current, total, last = sessions[player].current, sessions[player].total, sessions[player].last
    current:update(exp, lvl)
    total:update(exp, lvl)

    output:toScreen(player, lvl, total, current, last)
    output:toFile(player, lvl, total, current, last)

    current:incrementDuration()
    total:incrementDuration()

    lastInfo.player = player
    lastInfo.level = lvl
  elseif reader.status ~= nil then
    os.execute('cls')
    print(reader.status)
  else
    os.execute('cls')
    print("No player")

    if lastInfo.player ~= nil and sessions[lastInfo.player].current ~= nil then
      sessions[lastInfo.player].last = sessions[lastInfo.player].current
      sessions[lastInfo.player].current = nil
    end

    -- need to update files here because otherwise they wouldn't update
    -- while at the menu screen during save+quit
    if lastInfo.player then
      output:toFile(lastInfo.player, lastInfo.level, sessions[lastInfo.player].total, sessions[lastInfo.player].current, sessions[lastInfo.player].last)
    end
  end
  sleep(UPDATE_PERIOD)
end
