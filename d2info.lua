local memreader = require('memreader')
local D2Reader = require('d2info.d2reader')
local sleep = require('sleep')
local friendlyNumber = require('d2info.utils').friendlyNumber
local friendlyTime = require('d2info.utils').friendlyTime
local Session = require('d2info.session')

memreader.debugprivilege(true)
local reader = D2Reader.new()
local sessions = {}
local lastPlayer = nil

while true do
  os.execute('cls')
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

    print(string.format("%s\n", player))
    print(string.format("Overall (real-time): %s xp/min", friendlyNumber(total:realTimeExpPerMin())))
    print(string.format("Overall (game-time): %s xp/min", friendlyNumber(total:durationExpPerMin())))
    print(string.format("Current game: %s xp/min", friendlyNumber(current:realTimeExpPerMin())))
    print(string.format("Last game: %s xp/min", last and friendlyNumber(last:durationExpPerMin()) or "?"))
    print(string.format("\nEst time until level %d:", lvl+1))
    print(string.format(" %s (using real-time xp/min)", friendlyTime(total:realTimeToNextLevel())))
    print(string.format(" %s (using game-time xp/min)", friendlyTime(total:gameTimeToNextLevel())))
    print(string.format(" %s (using current game's xp/min)", friendlyTime(current:gameTimeToNextLevel())))
    print(string.format(" %s (using last game's xp/min)", last and friendlyTime(last:gameTimeToNextLevel()) or "?"))

    current:incrementDuration()
    total:incrementDuration()

    lastPlayer = player
  elseif reader.status ~= nil then
    print(reader.status)
  else
    print("No player")

    if lastPlayer ~= nil then
      sessions[lastPlayer].last = sessions[lastPlayer].current
      lastPlayer = nil
    end
  end
  sleep(1000)
end
