local utils = require('d2info.utils')
local lfs = require('lfs')
local printf, friendlyNumber, friendlyTime, toFile = utils.printf, utils.friendlyNumber, utils.friendlyTime, utils.toFile

local Output = {}
Output.__index = Output

function Output.new(outputDir)
  local self = setmetatable({}, Output)
  self.outputDir = outputDir or "output"
  if not lfs.attributes(self.outputDir) then
    assert(lfs.mkdir(self.outputDir))
  end
  return self
end

function Output:toScreen(player, level, total, current, last)
  os.execute('cls')
  printf("%s\n", player)
  printf("Overall (real-time): %s xp/min", friendlyNumber(total:realTimeExpPerMin()))
  printf("Overall (game-time): %s xp/min", friendlyNumber(total:durationExpPerMin()))
  printf("Current game: %s xp/min", current and friendlyNumber(current:realTimeExpPerMin()) or "-")
  printf("Last game: %s xp/min", last and friendlyNumber(last:durationExpPerMin()) or "-")
  printf("\nEst time until level %d:", level+1)
  printf(" %s (using real-time xp/min)", friendlyTime(total:realTimeToNextLevel()))
  printf(" %s (using game-time xp/min)", friendlyTime(total:gameTimeToNextLevel()))
  printf(" %s (using current game's xp/min)", current and friendlyTime(current:gameTimeToNextLevel()) or "-")
  printf(" %s (using last game's xp/min)", last and friendlyTime(last:gameTimeToNextLevel()) or "-")
  printf("\nExp gained (overall): %s", friendlyNumber(total:expGained()))
  printf("Exp gained (current game): %s", current and friendlyNumber(current:expGained()) or "-")
  printf("Exp gained (last game): %s", last and friendlyNumber(last:expGained()) or "-")
  printf("\nTicks gained (overall): %0.1f", total:ticksGained())
  printf("Ticks gained (current game): %0.1f", current and current:ticksGained() or 0)
  printf("Ticks gained (last game): %0.1f", last and last:ticksGained() or 0)
end

function Output:toFile(player, level, total, current, last)
  toFile(self.outputDir .. "/xpmin-realtime.txt", friendlyNumber(total:realTimeExpPerMin()))
  toFile(self.outputDir .. "/xpmin-gametime.txt", friendlyNumber(total:durationExpPerMin()))
  toFile(self.outputDir .. "/xpmin-currentgame.txt", current and friendlyNumber(current:realTimeExpPerMin()) or "-")
  toFile(self.outputDir .. "/xpmin-lastgame.txt", last and friendlyNumber(last:durationExpPerMin()) or "-")
  toFile(self.outputDir .. "/timetolevel-realtime.txt", friendlyTime(total:realTimeToNextLevel()))
  toFile(self.outputDir .. "/timetolevel-gametime.txt", friendlyTime(total:gameTimeToNextLevel()))
  toFile(self.outputDir .. "/timetolevel-currentgame.txt", current and friendlyTime(current:gameTimeToNextLevel()) or "-")
  toFile(self.outputDir .. "/timetolevel-lastgame.txt", last and friendlyTime(last:gameTimeToNextLevel()) or "-")
  toFile(self.outputDir .. "/ticksgained-overall.txt", string.format("%0.1f", total:ticksGained()))
  toFile(self.outputDir .. "/ticksgained-currentgame.txt", current and string.format("%0.1f", current:ticksGained()) or "-")
  toFile(self.outputDir .. "/ticksgained-lastgame.txt", last and string.format("%0.1f", last:ticksGained()) or "-")
end

return Output
