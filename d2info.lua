local memreader = require('memreader')
local D2Reader = require('d2info.d2reader')
local sleep = require('sleep')
local consoleWrite = require('d2info.utils').consoleWrite
local friendlyNumber = require('d2info.utils').friendlyNumber
local friendlyTime = require('d2info.utils').friendlyTime
local Session = require('d2info.session')

memreader.debugprivilege(true)
local reader = D2Reader.new()
local sessions = {}
local lastPlayer = nil

while true do
  local player = reader:getPlayerName()
  if player then
    local exp, lvl = reader:getExperience()

    if not sessions[player] then
      sessions[player] = {}
      sessions[player].total = Session.new(exp, lvl)
    end
    if player ~= lastPlayer then
      sessions[player].current = Session.new(exp, lvl)
    end

    local current, total, last = sessions[player].current, sessions[player].total, sessions[player].last
    current:update(exp, lvl)
    total:update(exp, lvl)

    consoleWrite(
      string.format(
        "\r%s: %s xp/min (overall) | %s xp/min (current game) | %s xp/min (last game) | time until level %d: %s",
        player,
        friendlyNumber(total:realTimeExpPerMin()),
        friendlyNumber(current:realTimeExpPerMin()),
        last and friendlyNumber(last:durationExpPerMin()) or "?",
        lvl+1, friendlyTime(total:realTimeToNextLevel())
      )
    )

    current:incrementDuration()
    total:incrementDuration()

    lastPlayer = player
  elseif reader.status ~= nil then
    consoleWrite("\r" .. reader.status)
  else
    consoleWrite("\rNo player")

    if lastPlayer ~= nil then
      sessions[lastPlayer].last = sessions[lastPlayer].current
      lastPlayer = nil
    end
  end
  sleep(1000)
end
